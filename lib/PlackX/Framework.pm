use 5.10.0;
use strict;
use warnings;

package PlackX::Framework;
use PlackX::Framework::Handler ();
use PlackX::Framework::Request ();
use PlackX::Framework::Response ();
use PlackX::Framework::Router ();
use PlackX::Framework::Router::Engine ();
use Module::Loaded ();

# Not everyone will need these modules, do not load by default
#use PlackX::Framework::Template ();
#use PlackX::Framework::URIx (); 

sub modules {
  return (
    'Handler'          => { autoload => 1, auto_load_subclass => 1, auto_create_subclass => 1 },
    'Request'          => { autoload => 1, auto_load_subclass => 1, auto_create_subclass => 1 },
    'Response'         => { autoload => 1, auto_load_subclass => 1, auto_create_subclass => 1 },
    'Router'           => { autoload => 1, auto_load_subclass => 1, auto_create_subclass => 1 },
    'Router::Engine'   => { autoload => 1, auto_load_subclass => 1, auto_create_subclass => 1 },
    'URIx'             => { autoload => 1, auto_load_subclass => 1,                           },
    'Template'         => {                auto_load_subclass => 1, auto_create_subclass => 1 },
  );
}

sub import {
  my $caller = caller(0);  # use this module will load or create subclasses in caller's namespace

  # Load the application's subclassed versions of PlackX::Framework::*
  my %modules = modules();
  foreach my $module (keys %modules) {
    my %loaded = ();

    # Attempt to load the user's subclass of the respective module
    if ($modules{$module}->{auto_load_subclass}) {
      $loaded{$module} = load_subclass($caller, $module);
    }

    # Create it
    if (!$loaded{$module} and $modules{$module}->{auto_create_subclass}) {
      generate_subclass($caller . '::' . $module => "PlackX::Framework::$module");
    }

    # Verify required modules are loaded
    if ($modules{$module}->{required}) {
      die "Could not load or create required module $_" unless Module::Loaded::is_loaded($caller . '::' . $module);
    }
  }

  export_app_sub($caller);
}

sub export_app_sub {
  my $destination_package = shift;
  no strict 'refs';
  *{$destination_package . '::app'} = sub {
    my $class         = shift;
    my $handler_class = $class . '::Handler';
    $handler_class->to_app;
  }
}

sub load_subclass {
  my $class   = shift;
  my $module  = shift;
  my $success = eval "require $class" . '::' . "$module; 1;";
  return $success;
}

sub generate_subclass {
  my ($new_class, $base_class) = @_;
  eval qq{
    package $new_class;
    use parent '$base_class';
    Module::Loaded::mark_as_loaded($new_class);
    1;
  } or die $@;
}

1;
__END__

=head1 NAME

PlackX::Framework - A thin framework for Plack-based web apps.


=head1 SYNOPSIS

This module is the root module for the PlackX::Framework web application
framework. It is responsible for loading all of the related modules as well as
the user's subclasses of these modules, creating empty subclasses of them if
necessary.

A simple PlackX::Framework application could be all in one .psgi file:

    # app.psgi
    package MyProject {
      use PlackX::Framework; # use, NOT use 'parent'
      use MyProject::Router; # exports `request', 'request_base', and 'filter'
      request '/' => sub {
         my ($request, $response) = @_;
         $response->body('Hello, ', $request->param('name'));
         return $response;
      };
    }
    MyProject->app;

However, a larger application would be typically laid out with separate modules
in separate files, for example in MyProject::Controller::* modules. Each should
use MyProject::Router if the DSL-style routing is desired.

This software is considered to be in an experimental, "alpha" stage. Use at 
your own risk.


=head1 DESCRIPTION

PlackX::Framework consists of the following modules:

PlackX::Framework
PlackX::Framework::Handler
PlackX::Framework::Request
PlackX::Framework::Response
PlackX::Framework::Router
PlackX::Framework::Router::Engine
PlackX::Framework::Template
PlackX::Framework::URIX

The statement "use PlackX::Framework" will automatically find and load all of
the required modules. Then it will look for subclasses of the modules listed 
above that exist in your namespace and load them, or create empty subclasses
for any that do not exist. The following example

    package MyProject {
        use PlackX::Framework;
        # ...app logic here...
    }

will attempt to load MyProject::Handler, MyProject::Request, MyProject::Response
and so on, or create them if they do not exist.

The PlackX::Framework::Request and PlackX::Framework::Response modules are
subclasses of Plack::Request and Plack::Response sprinkled with additional
features. See the documentation of those modules for details.

The PlackX::Framework::URIx module is a subclass of URI::Fast, with some
syntactic sugar.

The PlackX::Framework::Router::Engine is a subclass of Router::Boom with some
extra convenience methods. Normally, you would not have to use this module
directly. It is used by PlackX::Framework::Router internally.

The PlackX::Framework::Template module can automatically load and set up
Template Toolkit, offering several convenience methods. If you desire to use
a different templating system from TT, you may override as many methods as
necessary in your subclass. A new instance of this class is generated for
each request by the app() method of PlackX::Framework::Handler.


=head2 Why Another Framework?

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


=head2 Routes, Requests, and Request Filtering

See PlackX::Framework::Router for documentation on request routing and
filtering.


=head2 Templating

No Templating system is loaded by default, but PlackX::Framework can
automatically load and set up Template Toolkit if you:

    use MyProject::Template;

(assuming MyProject has `use`d PlackX::Framework).

Note that this feature relies on the import() method of your app's
PlackX::Framework::Template subclass being called (this subclass is also
created automatically if you do not have a MyApp/Template.pm module).
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
