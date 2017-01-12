package PlackX::Framework::App;

use strict;
use warnings;

sub app {
  my $class  = shift;
  my $env    = shift;

  $class =~ m/^(.+)\:\:App$/;
  my $app_namespace = $1;

  my $router   = "$app_namespace\::Router"->router;
  my $request  = "$app_namespace\::Request"->new($env);
  my $response = "$app_namespace\::Response"->new;
  my $template = "$app_namespace\::Template"->new($response);
  my $stash    = {};

  $request->set_stash($stash);
  $response->set_stash($stash);
  $response->set_template($template);

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
  return $response->finalize;
}

sub to_app {
  my $class = shift;
  return sub { $class->app(shift) };
}

1;
