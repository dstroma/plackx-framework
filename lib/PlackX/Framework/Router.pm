use v5.36;
package PlackX::Framework::Router {
  our $filters = {};
  our $bases   = {};
  our $engines = {};

  # Override in your subclass to change the export names
  sub global_filter_request_keyword { 'global_filter' }
  sub filter_request_keyword        { 'filter' }
  sub route_request_keyword         { 'route'  }
  sub uri_base_keyword              { 'base'   }

  sub engine ($class) { ($class.'::Engine')->instance; }

  sub import ($class, @extra) {
    my $export_to = caller(0);

    # Trap errors
    die "You must import from your app's subclass of PlackX::Framework::Router, not directly"
      if $class eq __PACKAGE__;

    # Remember which controller is using which router engine object
    $engines->{$export_to} = $class->engine;

    # Export
    foreach my $export_sub (qw/global_filter_request filter_request route_request uri_base/) {
      my $export_name = eval "$class->$export_sub\_keyword" or die $@;
      no strict 'refs';
      *{$export_to . '::' . $export_name} = \&{'DSL_' . $export_sub};
    }
  }

  sub DSL_filter_request ($when, $action, @slurp) {
    my ($package) = caller;

    die "usage: filter ('before' || 'after') => sub {}"
      unless $when eq 'before' or $when eq 'after';

    _add_filter($package, $when, {
      action     => _coerce_action_to_subref($action, $package),
      controller => $package,
      'when'     => $when,
      params     => \@slurp
    });
    return;
  }

  sub DSL_global_filter_request {
    my ($package) = caller;
    my $when    = shift;
    my $action  = pop;
    my $pattern = @_ ? shift : undef;

    die "usage: global_filter ('before' || 'after') => sub {}"
      unless $when eq 'before' or $when eq 'after';

    $engines->{$package}->add_global_filter(
      'when'  => $when,
      pattern => $pattern,
      action  => $action
    );

    return;
  }

  sub DSL_route_request (@args) {
    my ($package) = caller;
    my $action    = pop @args;
    my $routespec = shift @args;

    die 'expected coderef or hash as last argument'
      unless ref $action and (ref $action eq 'CODE' or ref $action eq 'HASH');

    if (@args) {
      my $verb = $routespec;
      $verb    = join('|', @$verb) if ref $verb;
      $routespec = shift @args;
      die 'incorrect usage' if ref $routespec;
      $routespec  = { $verb => $routespec };
    }

    $engines->{$package}->add_route(
      routespec   => $routespec,
      base        => $bases->{$package},
      prefilters  => _get_filters($package, 'before'),
      action      => _coerce_action_to_subref($action, $package),
      postfilters => _get_filters($package, 'after'),
    );
    return;
  }

  sub DSL_uri_base ($base) {
    my ($package) = caller;
    $bases->{$package} = _remove_trailing_slash($base);
    return;
  }

  # Class method-style (currently does not support base or filters) ###########
  sub add_route ($class, $spec, $action, %options) {
    my ($package) = caller;
    $options{'filter'} //= $options{'filters'};
    my $engine = ($engines->{$class} ||= $class->engine);
    $engine->add_route(
      routespec   => $spec,
      base        => $options{'base'}   ? _remove_trailing_slash($options{'base'}) : undef,
      prefilters  => _coerce_to_arrayref_or_undef($options{'filter'}{'before'}),
      action      => _coerce_action_to_subref($action, $package),
      postfilters => _coerce_to_arrayref_or_undef($options{'filter'}{'after' }),
    );
  }

  sub add_global_filter ($class, @args) {
    my $when    = shift @args;
    my $action  = pop @args;
    my $pattern = shift @args // undef;
    $class->engine->add_global_filter(
      'when'  => $when,
      $pattern ? (pattern => $pattern) : (),
      action  => $action
    );
  }

  # Helpers ###################################################################
  sub _remove_trailing_slash ($uri) { substr($uri, -1, 1) eq '/' ? substr($uri, 0, -1) : $uri }
  sub _get_filters ($class, $when)  { $filters->{$class}{$when} }

  sub _add_filter ($class, $when, $spec) {
    $filters->{$class}{$when} ||= [];
    push @{   $filters->{$class}{$when}   }, $spec;
  }

  sub _coerce_action_to_subref ($action, $package) {
    if (not ref $action) {
      $action = ($action =~ m/::/) ?
        \&{ $action } : \&{ $package . '::' . $action };
    } elsif (ref $action and ref $action eq 'HASH') {
        # TODO: Make convenience methods in Response class to shorten these
        if (my $template = $action->{template}) {
          $action = sub ($request, $response) {
            $response->template->render($template);
          };
        } elsif (my $text = $action->{text}) {
          $action = sub ($request, $response) {
            $response->content_type('text/plain');
            $response->body($text);
            return $response;
          };
        } elsif (my $html = $action->{html}) {
          $action = sub ($request, $response) {
            $response->content_type('text/html');
            $response->body($html);
            return $response;
          };
        } else {
          die 'unknown action specification';
        }
    }
    return $action;
  }

  sub _coerce_to_arrayref_or_undef ($val) {
    if (ref $val eq 'ARRAY' and @$val > 0) {
      return $val;
    } elsif (defined $val) {
      return [$val];
    } else {
      return undef;
    }
  }
}

1;

=pod

=head1 NAME

PlackX::Framework::Router - Parse routes and export DSL for PXF apps


=head1 SYNOPSIS

    package My::App::Controller {
      use My::App::Router;

      request_base '/myapp';

      filter before => sub ($request, $resp) { ... }

      filter after  => sub ($request, $resp) { ... }

      route '/'     => sub ($request, $resp) { ... }
    }


=head1 EXPORTS

This module exports the subroutines "filter", "global_filter", "route", and
"base" to the calling package. These can then be used like DSL keywords to lay
out your web app.

You can choose your own keyword names by overridding them in your subclass this
way:

    package MyApp::Router {
      use parent 'PlackX::Framework::Router';
      sub filter_request_keyword        { 'my_filter'; }
      sub global_filter_request_keyword { 'my_global_filter' }
      sub route_request_keyword         { 'my_route';  }
      sub uri_base_keyword              { 'my_base';   }
    }

For more detail, see the "DSL style" section.


=head1 CLASS-METHOD STYLE

You may add filters routes using class method calls, but this is not the
preferred way to use this module.

Mixing class method style and DSL style routing in the same app is not
recommended.

=over 4

=item add_route($SPEC, \&ACTION, %OPTIONS)

Adds a route matching $SPEC to execute \&ACTION. In the future, %OPTIONS
can contain keys 'base', 'prefilters', and/or 'postfilters'.

$ACTION should be a coderef, string containing a package and subroutine, e.g.
"MyApp::Controller::index", or a hashref containing one of the keys 'template',
'text', or 'html' with the value being a string containing a template filename,
plain text content to render, or html to render, respectively.

=item add_global_filter($WHEN, \&ACTION);

=item add_global_filter($WHEN, $PATTERN, \&ACTION);

Add a filter which will be applied to any route defined anywhere in the
application. If $PATTERN is defined, the filter will only be executed if the
request uri matches it. $PATTERN may be a string, scalar reference to a string,
or regex; $PATTERN is the same as in DSL style described below.

\&ACTION is a reference to a subroutine. The subroutine should return a false
value to continue with the next filter or route; if it returns a response
object, processing will stop and the response will be rendered.

=back


=head1 DSL-STYLE

=over 4

=item request_base $STRING;

Set the base URI path for all subsequent routes defined in the current package.

=item filter before|after => sub { ... };

Filter all subsequent routes. Your filter subroutine should return a false
value to continue request processing. $response->continue is available for
a semantic convenience. To render a response early, return the response
object.

=item global_filter before|after => sub { ... };

=item global_filter before|after => $PATTERN => sub { ... };

Adds a filter that can match any route anywhere in your application,
regardless of where it is defined. Optionally, you may supply a $pattern which
may be:

=over 4

=item - a string, in which case the filter will be executed if the request uri
        BEGINS WITH the string.

=item - a scalar reference to a string, in which case the filter will be executed
        only if it matches the request path exactly

=item - a reference to a regular expression, e.g. qr|^/restricted| which will be
        used to match the request uri path.

=back

=item route $URI_SPEC => $ACTION;

=item route $METHOD   => $PATH => $ACTION;

=item route $ARRAYREF => $ACTION;

=item route $HASHREF  => $ACTION;

Execute action \&ACTION for the matching uri described by $URI_SPEC. The
$URI_SPEC may contain patterns described by PXF's routing engine,
Router::Boom.

The $ACTION is a coderef, subroutine name, or hashref, as described in the
class method add_route, described above.

The $METHOD may contain more than one method, separated by a pipe, for
example, the string "get|post".

You may specify a list of $URI_SPECs in an $ARRAYREF.

You may specify a hashref of key-value pairs, where the key is the HTTP
request method, and the value is the desired URI path.

See the section below for examples of various combinations.

=back


=head1 EXAMPLES

    # Base example
    base '/myapp';

    # Filter example
    # Fat arrow operator allows us to use "before" or "after" without quotes.
    filter before => sub ($request, $response) {
      unless ($request->{cookies}{logged_in}) {
        $response->status(403);
        return $response;
      }
      $request->{logged_in} = 1;
      return;
    };

    # Simple route
    # Because of the request_base, this will actually match /myapp/index
    route '/index' => sub { ... };

    # Route with method
    route get => '/default' => sub { ... }
    route post => '/form'   => sub { ... }

    # Route with method, alternate formats
    route { get => '/login' } => sub { ... }

    route { post => '/login' } => sub {
      # do some processing to log in a user..
      ...

      # successful login
      $request->redirect('/user/home');

      # reroute the request
      $request->reroute('/try_again');
    };

    # Route with arrayref
    route ['/list/user', '/user/list', '/users/list'] => sub { ... };

    # Routes with hashref
    route { post => '/path1', put => '/path1' } => sub { ... };

    # Route with pattern matching
    # See Router::Boom for pattern options
    route { delete => '/user/:id' } => sub {
      my $request = shift;
      my $id = $request->route_param('id');
    };

    # Combination hashref arrayref
    route { get => ['/path1', '/path2'] } => sub {
      ...
    };

    # Routes with alternate HTTP verbs
    route 'get|post' => '/somewhere' => sub { ... };

    # Action hashref instead of coderef
    # Key can be one of "template", "text", or "html"
    route '/' => {
      template => 'index.tmpl'
    };

    route '/hello-world.txt' => {
      text => 'Hello World'
    };

    route '/hello-world.html' => {
      html => '<html><body>Hello World</body></html>'
    };


=head1 META

For author, copyright, and license, see PlackX::Framework.
