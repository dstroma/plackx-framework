package PlackX::Framework::Router::Engine;
use parent 'Router::Boom';

use warnings;
use strict;

our %routers;

sub router {
  my $class = shift;
  $routers{$class} ||= $class->new;
} 

sub match {
  my $self     = shift;
  my $request  = shift;
  my $req_path = $request->destination;
  my $req_meth = $request->method; 
  my @match    = $self->SUPER::match('/[' . $req_meth . ']' . $req_path);

  if (@match and @match == 2) {
    my ($destin, $captures) = @match;
    my %matchinfo = (%$destin, %$captures);
    delete $matchinfo{REQUEST_METHOD};
    return \%matchinfo;
  } else {
    return undef;
  }
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
          $router->add(path_with_base_and_method($path, $base, uc $key), \%params);
        }
      } else {
        $router->add(path_with_base_and_method($path, $base, uc $key), \%params);
      }
    }
  } elsif (ref $route eq 'ARRAY') {
    foreach $path (@$route) {
      $router->add(path_with_base_and_method($path, $base), \%params);
    }
  } else {
    $router->add(path_with_base_and_method($path, $base), \%params);
  }
}

sub path_with_base {
  my $path = shift;
  my $base = shift;
  return $path unless $base and length $base;

  $path = '/' . $path if substr($path, 0, 1) ne '/';
  return $base . $path;
}

sub path_with_method {
  my $path   = shift;
  my $method = shift;
  $method = $method ? '/[' . uc $method . ']' : '/[:REQUEST_METHOD]';
  $path   = $method . $path;
  return $path;
}

sub path_with_base_and_method {
  my $path   = shift;
  my $base   = shift;
  my $method = shift;
  $path = path_with_base($path, $base);
  $path = path_with_method($path, $method);
  return $path;
}

1;

