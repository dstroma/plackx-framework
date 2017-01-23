package PlackX::Framework::Controller;

use strict;
use warnings;
use Exporter;
use base 'Exporter';
our @EXPORT = our @EXPORT_OK = qw/request filter $request $response/;
our $filters = {};
our $request;  # Obviously not thread-safe
our $response; # Obviously not thread-safe

sub import {
  my $class = $_[0];
  {
    no strict 'refs';
    push @{$class.'::EXPORT'}, qw/request filter $request $response/;
  }
  $class->export_to_level(1, @_);

  # Enable signatures
  #require feature;
  #require warnings;
  #feature->import('signatures');
  #warnings->unimport('experimental::signatures');
}

#sub install_dsl_and_request_response_globals {
#  my $class = shift;
#  install_dsl($class);
#  install_request_response_globals($class);
#}

#sub install_dsl {
#  my $class = shift;
#  no strict 'refs';
#  *{$class . '::request'} = \&request;
#  *{$class . '::filter'}  = \&filter;
#}

#sub install_request_response_globals {
#  my $class = shift;
#  no strict 'refs';
#  my ($var1, $var2);
#  *{$class . '::request'}  = \${$class . '::request'};  # Obviously not thread-safe
#  *{$class . '::response'} = \${$class . '::response'}; # Obviously not thread-safe
#}

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

  unless ($when eq 'before' or $when eq 'after') {
    die "usage: filter 'before' => sub {} or filter 'after' => sub {}";
  }

  push @{_get_filters($package, $when)}, { subref => $coderef, controller => $package, 'when' => $when };
  return;
}

sub execute_filters {
  my $class    = shift;
  my $when     = shift;
  my $request  = shift;
  my $response = shift;
  my $filters  = _get_filters($class, $when);
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

1;
=pod

Examples:

package My::App::Controller;
use 'PlackX::Framework::Controller';

filter 'before' => sub {
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


