package PlackX::Framework::Controller;

use strict;
use warnings;
use Exporter;
use base 'Exporter';
our @EXPORT = our @EXPORT_OK = ('request', 'filter');
our $filters = {};

sub request {
  my $route     = shift;
  my $coderef   = shift;
  my ($package) = caller;

  my $app_namespace = _get_app_namespace($package);
  my $router = "$app_namespace\::Router"->router;
  $router->add_route($route, { subref => $coderef, controller => $package } );
  return;
}

sub filter {
  my $when      = shift;
  my $coderef   = shift;
  my ($package) = caller;
  push @{$package->_get_filters($when)}, { subref => $coderef, controller => $package, 'when' => $when };
  return;
}

sub execute_filters {
  my $class    = shift;
  my $when     = shift;
  my $request  = shift;
  my $response = shift;
  my $filters  = $class->_get_filters($when);
  return unless ref $filters;
  foreach my $filter (@$filters) {
    my $response = $filter->{subref}->($request, $response);
    return $response if $response and ref $response;
  }
  return;
}

sub _get_filters {
  my $class = shift;
  my $when  = shift;
  $filters->{$class}{$when} ||= [];
  return $filters->{$class}{$when};
}

sub _get_app_namespace {
  $_[0] =~ m/^(.+)\:\:Controller\:\:.+$/;
  return $1;
}

=pod

Examples:

package My::App::Controller;
use 'PlackX::Framework::Controller';

filter => sub {
  my $request  = shift;
  my $response = shift;
  
  unless ($request->{cookies}{logged_in}) {
    $response->status(403);
    return $response;
  }
  $request->{logged_in} = 1;
  return;
};

request '/index' => sub {
  $template->render_index;
};

request {get => '/index'} => sub {
  ...
};

request {post => '/index'} => sub {
  ...
};

request ['/list/user', '/user/list', '/users/list'] => sub {
  ...
};

request {post => '/path1', put => '/path1'} => sub {
  ...
};

request {delete => '/user/:id'} => sub {
   ...
};

request {get => ['/path1', '/path2']} => sub {

};


