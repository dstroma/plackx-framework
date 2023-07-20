use v5.10;
use strict;
use warnings;

package PlackX::Framework::App;
use Scalar::Util qw(blessed);
use Module::Loaded ();

# Public class method
sub to_app {
  my $class   = shift;
  return sub {
    $class->handle_request(shift)
  };
}

# Public class method
sub not_found_response {
  return [404, [], ['Not Found']];
}

sub error_response {
  return [500, [], ['Internal Server Error']];
}

sub handle_request {
  my $class         = shift;
  my $env_or_req    = shift;
  my $maybe_resp    = shift;
  my $app_namespace = $class->app_namespace;

  # Get or create request and response objects
  my $env      = $class->env_or_req_to_env($env_or_req);
  my $request  = $class->env_or_req_to_req($env_or_req);
  my $response = $maybe_resp || ($app_namespace . '::Response')->new;

  $request->set_app_class($class);

  # Set up stash
  my $stash = ($request->stash or $response->stash or {});
  $request->set_stash($stash);
  $response->set_stash($stash);

  # Store some things in the stash and clear flash
  $stash->{'_app_namespace'} = $app_namespace;
  $response->flash;

  # Try to set up templating lazy (app must subclass ::Template)
  if (Module::Loaded::is_loaded($app_namespace . '::Template')) {
    eval {
      my $template = ($app_namespace . '::Template')->new($response);
      $response->template($template);
    };
  }

  # Set response defaults
  $response->status(200);
  $response->content_type('text/html');

  return $class->route_request($request, $response);
}

sub route_request {
  my $class    = shift;
  my $request  = shift;
  my $response = shift;
  my $router   = ($class->app_namespace . '::Router::Engine')->router;

  if (my $match = $router->match($request)) {
    $request->set_route_parameters($match);

    # Execute prefilters
    my $prefilter_result = execute_filters($match->{prefilters}, $request, $response);
    return finalized_response($prefilter_result) if $prefilter_result;

    # Execute main action
    my $result = $match->{action}->($request, $response);

    # Check if the "response" is actually another "request" (despite the variable name)
    return $class->handle_request($result) if $result->is_request;
    return $class->error_response unless $result->is_response;
    $response = $result;

    # Execute postfilters
    my $postfilter_result = execute_filters($match->{postfilters}, $request, $response);
    return finalized_response($postfilter_result) if $postfilter_result;

    # Clean up
    if ($response->post_response_callbacks and ref $response->post_response_callbacks and scalar @{  $response->post_response_callbacks  }) {
      if ($request->env->{'psgix.cleanup'}) {
        push @{  $request->env->{'psgix.cleanup.handlers'}  }, @{  $response->post_response_callbacks  };
      } else {
        $_->($request->env) for @{  $response->post_response_callbacks  };
      }
    }

    # Finish
    return finalized_response($response) if is_valid_response($response);
  }

  return $class->not_found_response;
}

sub execute_filters {
  my $filters  = shift;
  my $request  = shift;
  my $response = shift;
  return unless $filters and ref $filters eq 'ARRAY';

  foreach my $filter (@$filters) {
    my $response = $filter->{action}->($request, $response, @{$filter->{params}});
    return $response if $response and is_valid_response($response);
  }

  return;
}

#######################################################################
# Helpers

sub is_valid_response {
  my $response = pop;
  return undef unless defined $response and ref $response;      # Bad  - must be defined and be a ref
  return 1 if ref $response eq 'ARRAY' and @$response == 3;     # Good - PSGI raw response arrayref
  return 1 if blessed $response and $response->can('finalize'); # Good - Plack-like response object with finalize() method
  return undef;
}

sub finalized_response {
  my $response = pop;
  return ref $response eq 'ARRAY' ? $response : $response->finalize;
}

sub app_namespace {
  my $class = shift;
  $class =~ m/^(.+)\:\:App$/;
  my $app_namespace = $1;
  return $app_namespace;
}

sub env_or_req_to_req {
  my $class         = shift;
  my $env_or_req    = shift;
  my $app_namespace = $class->app_namespace;

  if (ref $env_or_req and ref $env_or_req eq 'HASH') {
    return "$app_namespace\::Request"->new($env_or_req);
  } elsif (blessed $env_or_req and $env_or_req->isa('PlackX::Framework::Request')) {
    return $env_or_req;
  } else {
    die 'Neither a PSGI-type HASH reference nor a PlackX::Framework::Request object.';
  }
}

sub env_or_req_to_env {
  my $class         = shift;
  my $env_or_req    = shift;
  my $app_namespace = $class->app_namespace;

  if (ref $env_or_req and ref $env_or_req eq 'HASH') {
    return $env_or_req;
  } elsif (blessed $env_or_req and $env_or_req->isa('PlackX::Framework::Request')) {
    return $env_or_req->env;
  } else {
    die 'Neither a PSGI-type HASH reference nor a PlackX::Framework::Request object.';
  }
}

1;
