package PlackX::Framework::Router;
use base 'Router::Simple';

our $router;
sub router {
  $router ||= __PACKAGE__->new;
}

sub add_route {
  my $router  = shift;
  my $route   = shift;
  my $params  = shift;
  my $opts;
  my $path    = $route;
  if (ref $route eq 'HASH') {
    foreach my $key (keys %$route) {
      $path = $route->{$key};
      if (ref $path eq 'ARRAY') {
        my @paths = @$path;
        foreach $path (@paths) {
          $router->connect($path, { controller => $params->{controller}, subref => $params->{subref} }, { method => uc $key });
        }
      } else {
        $router->connect($path, { controller => $params->{controller}, subref => $params->{subref} }, { method => uc $key });
      }
    }
  } elsif (ref $route eq 'ARRAY') {
    foreach $path (@$route) {
      $router->connect($path, { controller => $params->{controller}, subref => $params->{subref} });
    }
  } else {
    $router->connect($path, { controller => $params->{controller}, subref => $params->{subref} });
  }
}

1;

