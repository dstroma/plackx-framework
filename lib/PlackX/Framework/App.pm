package PlackX::Framework::App;

use strict;
use warnings;
use Scalar::Util qw(blessed);

sub handle_request {
  my $class         = shift;
  my $env_or_req    = shift;
  my $maybe_resp    = shift;
  my $app_namespace = $class->app_namespace;

  my $env      = $class->env_or_req_to_env($env_or_req);
  my $request  = $class->env_or_req_to_req($env_or_req);
  my $response = $maybe_resp || "$app_namespace\::Response"->new;
  my $template = "$app_namespace\::Template"->new($response);
  my $stash    = {};

  $request->set_app_class($class);
  $request->set_stash($stash);
  $response->set_stash($stash);
  $response->template($template);

  # Set response defaults
  $response->status(200);
  $response->content_type('text/html');

  return $class->route($request, $response);
}

sub route {
  my $class    = shift;
  my $request  = shift;
  my $response = shift;
  my $env      = $request->env;
  my $router   = $class->app_namespace . "::Router"->router;

  if (my $routematch = $router->match($env)) {
    $request->set_route_parameters($routematch);
    my $controller = $routematch->{controller};

    my $response_f = PlackX::Framework::Controller::execute_filters($controller, 'before', $request, $response);
    if ($response_f and ref $response_f) {
      $response = $response_f;
    } else {
      if ($routematch->{subref}) {
        $response = $routematch->{subref}->($request, $response);
      } elsif (my $action = $routematch->{action}) {
        $response = $controller->$action(%$routematch); #backward-compat
      } else {
        die "Route match found but no action or subref";
      }
    }
    my $response_f2 = PlackX::Framework::Controller::execute_filters($controller, 'after', $request, $response);
    $response = $response_f2 if $response_f2 and ref $response_f2;
  }
  
  return $class->not_found_response unless $response and ref $response;
  return ref $response eq 'ARRAY' ? $response : $response->finalize;
}

sub reroute {
  my $class   = shift;
  my $request = shift;
  my $where   = shift;

  $request->{env}{'PATH_INFO'} = $where;
  $class->handle_request($request);
}

sub not_found_response {
  return [404, [], ['Not Found']];
}

sub to_app {
  my $class = shift;
  return sub { $class->handle_request(shift) };
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
