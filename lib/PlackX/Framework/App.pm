package PlackX::Framework::App;

use strict;
use warnings;
use Scalar::Util qw(blessed);

sub app {
  my $class         = shift;
  my $env_or_req    = shift;
  my $app_namespace = $class->app_namespace;

  my $request  = $class->env_or_req_to_req($env_or_req);
  my $router   = "$app_namespace\::Router"->router;
  my $response = "$app_namespace\::Response"->new;
  my $template = "$app_namespace\::Template"->new($response);
  my $stash    = {};

  $request->set_stash($stash);
  $response->set_stash($stash);
  $response->template($template);

  $response->status(200);
  $response->content_type('text/html');

  if (my $m = $router->match($env)) {
    my $controller = $m->{controller};
    my $response_f = $controller->execute_filters('before', $request, $response);
    if ($response_f and ref $response_f) {
      $response = $response_f;
    } else {
      if ($m->{subref}) {
        $response = $m->{subref}->($request, $response);
      } elsif (my $action = $m->{action}) {
        $response = $controller->$action(%$m);
      } else {
        die "Route match found but not action or subref";
      }
    }
    my $response_f2 = $controller->execute_filters('after', $request, $response);
    $response = $response_f2 if $response_f2 and ref $response_f2;
  }
  
  return $response if ref $response eq 'ARRAY';
  return $response->finalize if ref $response;
  return [404, [], ['Not Found']];
}

sub to_app {
  my $class = shift;
  return sub { $class->app(shift) };
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
  my $req;

  if (ref $env_or_req and ref $env_or_req eq 'HASH') {
    $req = "$app_namespace\::Request"->new($env_or_req);
  } elsif (blessed $env_or_req and $env_or_req->isa('PlackX::Framework::Request')) {
    $req = $env_or_req;
  } else {
    die 'Neither a PSGI-type HASH reference nor a PlackX::Framework::Request object.';
  }

  return $req;
}

1;
