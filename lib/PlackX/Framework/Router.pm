use v5.40;
package PlackX::Framework::Router {
  our $filters = {};
  our $bases   = {};
  our $engines = {};

  sub import ($class, @extra) {
    my $export_to = caller(0);

    # Trap errors
    die "You must import from your app's subclass of PlackX::Framework::Router, not directly"
      if $class eq __PACKAGE__;

    # Remember which controller is using which router engine object
    $engines->{$export_to} = $class->engine;

    # Export
    { no strict 'refs';
      *{$export_to . '::' . $_} = \&{'DSL_'.$_} for qw(filter request request_base);
    }
  }

  sub engine ($class) {
    my $engine_class = $class . '::Engine';
    return $engine_class->instance;
  }

  sub DSL_filter ($when, $action, @slurp) {
    my ($package) = caller;

    die "usage: filter ('before' || 'after') => sub {}"
      unless $when eq 'before' or $when eq 'after';

    _add_filter($package, $when, {
      action     => _coerce_action_to_subref($action, $package);
      controller => $package,
      'when'     => $when,
      params     => \@slurp
    });
    return;
  }

  sub DSL_request ($routespec, $action) {
    my ($package) = caller;
    $engines->{$package}->add_route(
      routespec   => $routespec,
      base        => $bases->{$package},
      prefilters  => _get_filters($package, 'before'),
      action      => _coerce_action_to_subref($action, $package),
      postfilters => _get_filters($package, 'after'),
    );
    return;
  }

  sub DSL_request_base ($base) {
    my ($package) = caller;
    $bases->{$package} = _remove_trailing_slash($base);
    return;
  }

  # Class method-style (currently does not support base or filters) ###########
  sub add_route ($class, $spec, $action) {
    my ($package) = caller;

    my $engine = ($engines->{$class} ||= $class->engine);
    $engine->add_route(
      routespec   => $spec,
      #base        => $bases->{$package},
      #prefilters  => _get_filters($package, 'before'),
      action      => _coerce_action_to_subref($action, $package),
      #postfilters => _get_filters($package, 'after'),
    );
  }

  sub add_filter {
    die 'Not implemented. For request filtering please use the DSL API.';
  }

  # Helpers ###################################################################
  sub _remove_trailing_slash ($uri) {
    return substr($uri, -1, 1) eq '/' ? substr($uri, 0, -1) : $uri;
  }

  sub _get_filters ($class, $when) {
    return $filters->{$class}{$when};
  }

  sub _add_filter ($class, $when, $spec) {
    $filters->{$class}{$when} ||= [];
    push @{   $filters->{$class}{$when}   }, $spec;
  }

  sub _coerce_action_to_subref ($action, $package) {
    if (not ref $action) {
      $action = ($action =~ m/::/) ?
        \&{ $action } : $action = \&{ $package . '::' . $action };
    }
    return $action;
  }
}

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


