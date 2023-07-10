package PlackX::Framework::App;

use strict;
use warnings;
use Scalar::Util qw(blessed);
use Try::Tiny;

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

  # Try to set up templating lazy (app must subclass ::Template)
  try {
    # TODO: See if $app_namespace::Template is loaded before trying to call new on it
    my $template = ($app_namespace . '::Template')->new($response);
    $response->template($template);
  };

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

  if (my $match = $router->match($request->env)) {
    $request->set_route_parameters($match);

    # Execute prefilters
    my $prefilter_result = execute_filters($match->{prefilters}, $request, $response);
    return finalized_response($prefilter_result) if $prefilter_result;

    # Execute main action
    $response = $match->{action}->($request, $response);

    # Check if the "response" is actually another "request" (despite the variable name)
    if ($response->is_request) {
      my $request = $response;
      return $class->handle_request($request);
    }

    # Execute postfilters
    my $postfilter_result = execute_filters($match->{postfilters}, $request, $response);
    return finalized_response($postfilter_result) if $postfilter_result;

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
