use v5.10;
use strict;
use warnings;

package PlackX::Framework::Router;

our @EXPORT  = qw(request request_base filter);
our $filters = {};
our $bases   = {};
our $routers = {};

sub import {
  my $class     = shift;
  my $export_to = caller(0);
  my @wants     = @_;

  # Trap errors
  die "You must import from your app's subclass of PlackX::Framework::Router, not directly"
    if $class eq __PACKAGE__;

  # Remember which controller is using which router engine object
  # example: 
  #   `use MyApp::Router;` will cause the below line to become
  #   `$routers->{MyApp::Controller::Login} = MyApp::Router->engine`
  $routers->{$export_to} = $class->engine;

  # Determine what to export
  my @exports = @EXPORT;
  if (@wants > 0) {
    my %exports = map { $_ => 1 } @EXPORT;
    for my $want (@wants) {
      die "$class does not export $want" unless $exports{$want};
    } 
    @exports = @wants;
  }

  # Export
  no strict 'refs';
  foreach my $exportsub (@exports) {
    *{$export_to . '::' . $exportsub} = \&{$exportsub};
  }
}

# DSL-style filter route
sub filter {
  my $when      = shift;
  my $action    = shift;
  my @slurp     = @_;
  my ($package) = caller;

  unless ($when eq 'before' or $when eq 'after') {
    die "usage: filter ('before' || 'after') => sub {}";
  }

  $action = _coerce_action_to_subref($action, $package);

  _add_filter($package, $when, {
    action     => $action,
    controller => $package,
    'when'     => $when,
    params     => \@slurp
  });
  return;
}

# DSL-style request route
sub request {
  my $routespec = shift;
  my $action    = shift;
  my ($package) = caller;
  my $router    = $routers->{$package};

  $action = _coerce_action_to_subref($action, $package);

  $router->add_route(
     routespec   => $routespec,
     base        => $bases->{$package},
     prefilters  => _get_filters($package, 'before'),
     action      => $action,
     postfilters => _get_filters($package, 'after'),
  );

  return;
}

# DSL-style request base URI
sub request_base {
  my ($package) = caller;
  my $base      = shift;
  $base = _remove_trailing_slash_from_uri($base);
  $bases->{$package} = $base;
}

# Class method-style route
# Currently does not support base or filters
sub add_route {
  my $class  = shift;
  my $spec   = shift;
  my $action = shift;
  my ($package) = caller;

  $routers->{$class} ||= $class->engine;
  my $router = $routers->{$class};

  $action = _coerce_action_to_subref($action, $package);

  $router->add_route(
     routespec   => $spec,
     #base        => $bases->{$package},
     #prefilters  => _get_filters($package, 'before'),
     action      => $action,
     #postfilters => _get_filters($package, 'after'),
  );
}

# Class method-style filter
sub add_filter {
  die 'Not implemented. For request filtering please use the DSL API.';
}

sub engine {
  my $class        = shift;
  my $engine_class = $class . '::Engine';
  return $engine_class->instance;
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

sub _coerce_action_to_subref {
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


