package PlackX::Framework::Router;
use base 'Router::Simple';

our $router;
sub router {
  my $class = shift;
  $router ||= $class->new;
}

sub add_route {
  my $router  = shift;
  my $route   = shift;
  my $params  = shift;
  my $path    = $route;
  my $base    = $params->{base};
  if (ref $route eq 'HASH') {
    foreach my $key (keys %$route) {
      $path = $route->{$key};
      if (ref $path eq 'ARRAY') {
        my @paths = @$path;
        foreach $path (@paths) {
          $router->connect(path_with_base($path, $base), { controller => $params->{controller}, subref => $params->{subref} }, { method => uc $key });
        }
      } else {
        $router->connect(path_with_base($path, $base), { controller => $params->{controller}, subref => $params->{subref} }, { method => uc $key });
      }
    }
  } elsif (ref $route eq 'ARRAY') {
    foreach $path (@$route) {
      $router->connect(path_with_base($path, $base), { controller => $params->{controller}, subref => $params->{subref} });
    }
  } else {
    $router->connect(path_with_base($path, $base), { controller => $params->{controller}, subref => $params->{subref} });
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

