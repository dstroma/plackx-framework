package PlackX::Framework::Router::Engine;
use parent 'PlackX::Framework::Router::Engine::Boom';

1;

=pod

our %routers;

sub router {
  my $class = shift;
  $router{$class} ||= $class->new;
} 

sub add_route {
  my $router  = shift;
  my %params  = @_;
  my $route   = delete $params{routespec};
  my $base    = delete $params{base};
  my $path    = $route;

  if (ref $route eq 'HASH') {
    foreach my $key (keys %$route) {
      $path = $route->{$key};
      if (ref $path eq 'ARRAY') {
        my @paths = @$path;
        foreach $path (@paths) {
          $router->connect(path_with_base($path, $base), \%params, { method => uc $key });
        }
      } else {
        $router->connect(path_with_base($path, $base), \%params, { method => uc $key });
      }
    }
  } elsif (ref $route eq 'ARRAY') {
    foreach $path (@$route) {
      $router->connect(path_with_base($path, $base), \%params);
    }
  } else {
    $router->connect(path_with_base($path, $base), \%params);
  }
}

sub path_with_base {
  my $path = shift;
  my $base = shift;
  return $path unless $base and length $base;

  $path = '/' . $path if substr($path, 0, 1) ne '/';
  return $base . $path;
}

1;

