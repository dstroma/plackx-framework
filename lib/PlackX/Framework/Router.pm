package PlackX::Framework::Router;

use strict;
use warnings;

our $filters = {};
our $bases   = {};
our $routers = {};

sub import {
  my $class     = shift;
  my $export_to = caller(0);

  # Trap errors
  die "You must import from your app's sublcass of PlackX::Framework::Router, not directly"
    if $class eq __PACKAGE__;

  # Remember which controller is using which router engine object
  $routers->{$export_to} = $class->engine; # this might be a bug?

  # Export
  no strict 'refs';
  foreach my $exportsub (qw(request request_base filter)) {
    *{$export_to . '::' . $exportsub} = \&{$exportsub};
  }
}

sub filter {
  my $when      = shift;
  my $action    = shift;
  my @slurp     = @_;
  my ($package) = caller;

  unless ($when eq 'before' or $when eq 'after') {
    die "usage: filter ('before' || 'after') => sub {}";
  }

  $action = _action_to_subref($action, $package);

  _add_filter($package, $when, {
    action     => $action,
    controller => $package,
    'when'     => $when,
    params     => \@slurp
  });
  return;
}

sub request {
  my $routespec = shift;
  my $action    = shift;
  my ($package) = caller;
  my $router    = $routers->{$package};

  $action = _action_to_subref($action, $package);

  $router->add_route(
     routespec   => $routespec,
     base        => $bases->{$package},
     prefilters  => _get_filters($package, 'before'),
     action      => $action,
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

sub _action_to_subref {
  my ($action, $package) = @_;
  if (not ref $action) {
    if ($action =~ m/::/) {
      $action = \&{ $action };
    } else {
      $action = \&{ $package . '::' . $action };
    }
  }
  return $action;
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


