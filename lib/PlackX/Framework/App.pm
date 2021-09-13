package PlackX::Framework::App;

use strict;
use warnings;
use Scalar::Util qw(blessed);
use Try::Tiny;

# Public class method
sub to_app {
  my $class = shift;
  return sub { 
    $class->handle_request(shift)
  };
}

# Public class method
# Normally should be called as $request->reroute($where)
sub handle_reroute {
  my $class    = shift;
  my $request  = shift;
  my $where_to = shift;

  # TODO - See if there is a less hacky way to do this, and check compatibility with different servers/environments
  $request->{'env'}{'PATH_INFO'} = $where_to;
  return $class->handle_request($request); # TODO maybe this should just be ->route or maybe we need both a reroute method and a rehandle method
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
  my $response = $maybe_resp || "$app_namespace\::Response"->new;

  $request->set_app_class($class);

  # Set up stash
  my $stash = {};
  $request->set_stash($stash);
  $response->set_stash($stash);

  # Try to set up templating
  # Do it lazily -- only if the MyApp::Template module is loaded
  try {
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
  my $env      = $request->env;
  my $router   = ($class->app_namespace . '::Router')->router;

  if (my $routematch = $router->match($env)) {
    $request->set_route_parameters($routematch);
    my $controller = $routematch->{controller};

    # Before filter (TODO - change name to 'prefilter'?)
    my $before_result = PlackX::Framework::Controller::execute_filters($controller, 'before', $request, $response);
    return finalized_response($before_result) if $before_result and is_valid_response($before_result);

    # Main request
    if ($routematch->{subref}) {
      $response = $routematch->{subref}->($request, $response);
    } elsif (my $action = $routematch->{action}) {
      $response = $controller->$action(%$routematch); #backward-compat (TODO - figure out why I did this)
    } else {
      die "Route match found but no action or subref";
    }

    # After filter (TODO - change name to 'postfilter'?)
    my $after_result = PlackX::Framework::Controller::execute_filters($controller, 'after', $request, $response);
    return finalized_response($after_result) if $after_result and is_valid_response($after_result);

    # Finish
    return finalized_response($response) if is_valid_response($response);
  }
  
  return $class->not_found_response;
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

#sub is_valid_response_arrayref {
#  my $response = pop;
#  return ($response and ref $response eq 'ARRAY' and @$response == 3) ? 1 : undef;
#}
#
#sub is_valid_response_object {
#  my $response = pop;
#  return ($response and ref $response and blessed $response and $response->can('finalize')) ? 1 : undef;
#}

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
