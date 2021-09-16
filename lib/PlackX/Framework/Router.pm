package PlackX::Framework::Router;

use strict;
use warnings;

our $filters = {};
our $bases   = {};
our $routers = {};

sub import {
  my $router_class     = shift;
  my $controller_class = caller(0);

  # Remember which controller is using which router engine object
  $routers->{$controller_class} = $router_class->engine;

  # Export
  no strict 'refs';
  foreach my $exportsub (qw(request request_base filter)) {
    *{$controller_class . '::' . $exportsub} = \&{$exportsub};
  }
}

sub filter {
  my $when      = shift;
  my $coderef   = shift;
  my @slurp     = @_;
  my ($package) = caller;

  unless ($when eq 'before' or $when eq 'after') {
    die "usage: filter ('before' || 'after') => sub {}";
  }

  _add_filter($package, $when, {
    action     => $coderef,
    controller => $package,
    'when'     => $when,
    params     => \@slurp
  });
  return;
}

sub request {
  my $routespec = shift;
  my $coderef   = shift;
  my ($package) = caller;
  my $router    = $routers->{$package};

  $router->add_route(
     routespec   => $routespec,
     base        => $bases->{$package},
     prefilters  => _get_filters($package, 'before'),
     action      => $coderef,
     postfilters => _get_filters($package, 'after'),
  );
  return;
}

sub request_base {
  my ($package) = caller;
  my $base      = shift;
  $base = _remove_trailing_slash_from_uri($base);
  $bases->{$package} = $base;
}

sub engine {
  my $class        = shift;
  my $engine_class = $class . '::Engine';
  return $engine_class->router;
}

sub _remove_trailing_slash_from_uri {
  my $uri = shift;
  $uri = substr($uri, 0, -1) if substr($uri, -1, 1) eq '/';
  return $uri;
}

sub _get_filters {
  my $class = shift;
  my $when  = shift;
  return $filters->{$class}{$when};
}

sub _add_filter {
  my $class = shift;
  my $when  = shift;
  my $spec  = shift;
  $filters->{$class}{$when} ||= [];
  push @{   $filters->{$class}{$when}   }, $spec;
}
  
1;

=pod

Examples:

package My::App::Controller;
use My::App::Router;

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
  ...
  $template->render_index;
};

request {get => '/login'} => sub {
  # show login form
  ...
};

request {post => '/login'} => sub {
  my $request  = shift;
  my $response = shift;

  # do some processing to log in a user..
  ...

  # successful login
  $request->redirect('/user/home');

  # reroute the request
  $request->reroute('/try_again');
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


