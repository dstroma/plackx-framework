use v5.40;
use Module::Loaded ();
package PlackX::Framework {
  sub required_modules { qw(Handler Request Response Router Router::Engine) }
  sub optional_modules { qw(URIx Template) }

  # Export ->app and load parent classes and load or create subclasses
  sub import (@options) {
    my %options = map { $_ => 1 } @options;
    my $caller  = caller(0);
    export_app_sub($caller);

    # Load or create required modules, attempt to load optional ones
    foreach my $module (required_modules()) {
      eval 'require PlackX::Framework::'.$module or die $@; # Load parent or die
      my $loaded = eval 'require '.$caller.'::'.$module;    # Load subclass maybe
      generate_subclass($caller.'::'.$module, 'PlackX::Framework::'.$module)
        if !$loaded;
    }
    foreach my $module (optional_modules()) {
      my $loaded = eval 'require '.$caller.'::'.$module;    # Load subclass maybe
      generate_subclass($caller.'::'.$module, 'PlackX::Framework::'.$module)
        if !$loaded and ($options{$module} or $options{':'.lc($module)} or $options{':all'});
    }
    export_app_namespace_sub($caller, $_) for (required_modules(), optional_modules());
  }

  # Export app() sub to the app's main package
  sub export_app_sub ($destination_namespace) {
    no strict 'refs';
    *{$destination_namespace . '::app'} = sub ($class, @options) {
      state $handler_class = $class . '::Handler';
      $handler_class->to_app(@options);
    }
  }

  # Export app_namespace() to App::Request, App::Response, etc.
  sub export_app_namespace_sub ($namespace, $module) {
    no strict 'refs';
    my $exists = eval $namespace.'::'.$module.'::app_namespace()';
    die "app_namespace(): expected $namespace, got $exists" if $exists and $exists ne $namespace;
    *{$namespace.'::'.$module.'::app_namespace'} = sub { $namespace } unless $exists;
  }

  # Helper to create a subclass and mark as loaded
  sub generate_subclass ($new_class, $parent_class) {
    eval qq{
      package $new_class { use parent '$parent_class' }
      return Module::Loaded::mark_as_loaded('$new_class');
    } or die "Cannot create class: $@";
  }
}

=pod

=head1 NAME

PlackX::Framework - A thin framework for PSGI/Plack web apps.


=head1 SYNOPSIS

This is a micro-framework for PSGI web apps, based on Plack. A simple
PlackX::Framework application could be all in one .psgi file:

    # app.psgi
    package MyProject {
      use PlackX::Framework; # loads and sets up the framework and subclasses
      use MyProject::Router; # exports router DSL
      request '/' => sub ($request, $response) {
         $response->body('Hello, ', $request->param('name'));
         return $response;
      };
    }
    MyProject->app;

A larger application would be typically laid out with separate modules in
separate files, for example in MyProject::Controller::* modules. Each should
use MyProject::Router if the DSL-style routing is desired.

This software is considered to be in an experimental, "alpha" stage. Use at 
your own risk.

=head1 DESCRIPTION

=head2 Overview and Required Components

PlackX::Framework consists of the required modules:

PlackX::Framework
PlackX::Framework::Handler
PlackX::Framework::Request
PlackX::Framework::Response
PlackX::Framework::Router
PlackX::Framework::Router::Engine

And the following optional modules:

PlackX::Framework::Template
PlackX::Framework::URIx

The statement "use PlackX::Framework" will automatically find and load all of
the required modules. Then it will look for subclasses of the modules listed 
above that exist in your namespace and load them, or create empty subclasses
for any required modules that do not exist. The following example

    package MyProject {
        use PlackX::Framework;
        # ...app logic here...
    }

will attempt to load MyProject::Handler, MyProject::Request,
MyProject::Response and so on, or create them if they do not exist.


=head2 Optional Components

The Template and URIx modules are included in the distribution, but loading
them is optional - to save memory and compile time if they are not needed.
Just as with the required modules, you can subclass them yourself, or you can
automatically generate them like so:

    package MyProject {
        # Automagically generate MyProject::Template and ::URIx
        use PlackX::Framework qw(Template URIx);

        # Or automatically generate/load all optional modules
        use PlackX::Framework qw(:all);
    }

To reiterate, the above is only necessary if you you do not have
MyProject/{Optional Module}.pm in your @INC and want to automatically create
them.


=head2 The Pieces and How They Work Together

=head3 PlackX::Framework

PlackX::Framework is basically a management module, that is responsible for
loading required and optional components. It exports one mandatory symbol,
app(), to the calling package.

=head3 PlackX::Framework::Handler

PlackX::Framework::Handler is the package responsible for request processing.
You would not normally have to subclass this module manually unless you would
like to customize behavior of the framework.

=head3 PlackX::Framework::Request
=head3 PlackX::Framework::Response

The PlackX::Framework::Request and PlackX::Framework::Response modules are
subclasses of Plack::Request and Plack::Response sprinkled with additional
features.

=item stash()

Both feature a shared "stash" which is a hashref in which you can store any
data you would like. The "stash" is not a user session but a way to
temporarily store information during a request/response cycle. It is
re-initialized for each cycle.

=item flash()

They also feature a "flash" cookie which you can use to store information on
the user end for one cycle. It is automatically cleared in the following
cycle. For example...

    $response->flash('Goodbye!'); # Store message in a cookie

On the next request:

    $request->flash; # Returns 'Goodbye!'.

During the response phase, the flash cookie is cleared, unless you set another
one.

=head3 PlackX::Framework::Router

This module exports the request, request_base, and filter functions to give you
a minimalistic web app controller DSL. You can import this into your main app
package or separate controller packages.

    # Set up the app
    package MyApp {
      use PlackX::Framework;
      # You can also use MyApp::Router here...
    }

    # Note: the name of your controller module doesn't matter, but it must
    # import from your subclass, e.g., MyApp::Router, not directly from
    # PlackX::Framework::Router!
    package MyApp::Controller {
      use MyApp::Router;
      request_base '/app';
      request '/home' => sub {
        ...
      };
      request { post => '/login' } => sub {
        ...
      };
    }


=head3 PlackX::Framework::Router::Engine

The PlackX::Framework::Router::Engine is a subclass of Router::Boom with some
extra convenience methods. Normally, you would not have to use this module
directly. It is used by PlackX::Framework::Router internally.


=head3 The PlackX::Framework::Template

The PlackX::Framework::Template module can automatically load and set up
Template Toolkit, offering several convenience methods. If you desire to use
a different templating system from TT, you may override as many methods as
necessary in your subclass. A new instance of this class is generated for
each request by the app() method of PlackX::Framework::Handler.


=head3 PlackX::Framework::URIx

The optional PlackX::Framework::URIx module is a subclass of URI::Fast, with
some syntactic sugar for manipulating query string. It is made available to
your request objects through $request->urix (the x is to not confuse it
with the Plack::Request uri method).


=head3 PlackX::Framework::Util

Mainly used internally.


=head1 Why Another Framework?

After converting a mod_perl2 web application to use Plack instead, where
Plack::Request and Plack::Response replaced Apache2::Request and
Apache2::Response, I realized I was basically using Plack as a low-level
framework with some glue code and extra features. That framework has been
extracted, refactored, and expanded into this product.

The end result is a simple, lightweight framework that is higher level
than using the raw Plack building blocks, although it does not have as many
features as other frameworks. Here are some advantages:

 - A basic PlackX::Framework "Hello World" application loads 75% faster
   than a Dancer2 application and 70% faster than a Mojolicious::Lite app.
   (The author has not benchmarked request/response times.)

 - A basic PlackX::Framework "Hello World" application uses approximately
   one-third the memory of either Dancer2 or Mojolicious::Lite (~10MB compared
   to ~30MB for each of the other two).

 - PlackX::Framework has few non-core dependencies (it has more than 
   Mojolicious, which has zero, but fewer than Dancer2, which has a lot.)

 - PlackX::Framework has some magic, but not too much. It can be easily
   overriden with subclassing. You can use the bundled router engine
   or supply your own. You can use Template Toolkit automagically or use
   a different template engine.

If the above isn't enough justification for this module's mere existence,
then this should be: TIMTOWTDI. The author makes no claims that this framework
is better than any other framework except for the few trivial ones described
above.


=head2 Goals and Roadmap

The goal of this project is to continue to be a lightweight framework that
works closely with the PSGI specification. Future versions may require
newer versions of perl. It is possible I may rewrite this module to use
perl's built-in subroutine signatures, the new class feature, and whatever
the future of perl has in store. If this is done, it may be released under
a different name such that this module can continue to work with older
perl versions.


=head2 Object Orientation

PlackX::Framework has an object-oriented design philosophy that uses both
inheritance and composition to implement its features. Symbols exported are
limited to avoid polluting your namespace, however, a lot of the "magic" is
implemented with the import() method, so be careful about using empty
parenthesis in your use statements, as this will prevent the import() method
from being called and may break some magic.

Also be careful about whether you should use a module or subclass it.
Generally, modifying the behavior of the framework itself will involve
subclassing, while using the framework will not.


=head2 Configuration

=head3 uri_prefix

In your application's root namespace, you can set the base URL for requests
by defining a uri_prefix subroutine.

    package MyApp {
      use PlackX::Framework;
      sub uri_prefix { '/app' }
    }


=head2 Routes, Requests, and Request Filtering

See PlackX::Framework::Router for documentation on request routing and
filtering.


=head2 Templating

No Templating system is loaded by default, but PlackX::Framework can
automatically load and set up Template Toolkit if you:

    use MyProject::Template;

(assuming MyProject has imported from PlackX::Framework).

Note that this feature relies on the import() method of your app's
PlackX::Framework::Template subclass being called (this subclass is also
created automatically if you do not have a MyApp/Template.pm file).
Therefore, the following will not load Template Toolkit:

    use MyApp::Template ();  # Template Toolkit is not loaded
    require MyApp::Template; # Template Toolkit is not loaded

If you want to supply Template Toolkit with configuration options, you can
add them like this

    use MyApp::Template (INCLUDE_PATH => 'template');

If you want to use your own templating system, create a MyApp::Template
module that subclasses PlackX::Framework::Template. Then override the
get_template_system_object() method with your own code to create and/or
retrieve your template system object.


=head2 Model Layer

This framework is databse/ORM agnostic, you are free to choose your own or use
plain DBI/SQL.


=head1 EXPORT

This module will export the method app, which returns the code reference of
your app in accordance to the PSGI specification. (This is actually a shortcut
to ::App->to_app.)


=head1 DEPENDENCIES

Plack
Router::Boom


=head2 Optional Dependencies

URI::Fast
Template


=head1 SEE ALSO

PSGI
Plack
Plack::Request
Plack::Response


=head1 AUTHOR

Dondi Michael Stroma, E<lt>dstroma@gmail.com<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2023 by Dondi Michael Stroma


=cut
