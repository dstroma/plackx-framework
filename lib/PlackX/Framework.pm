package PlackX::Framework;

use strict;
use warnings;
use 5.010000;

use Module::Loaded ();

use PlackX::Framework::App ();
use PlackX::Framework::Request ();
use PlackX::Framework::Response ();
use PlackX::Framework::Router ();
use PlackX::Framework::Router::Engine ();

# Not everyone will need these modules, do not load by default
#use PlackX::Framework::Template ();
#use PlackX::Framework::URI (); 

our %modules = (
  App              => { required => 1, auto_load_subclass => 1, auto_create_subclass => 1 },
  Request          => { required => 1, auto_load_subclass => 1, auto_create_subclass => 1 },
  Response         => { required => 1, auto_load_subclass => 1, auto_create_subclass => 1 },
  Router           => { required => 1, auto_load_subclass => 1, auto_create_subclass => 1 },
  'Router::Engine' => { required => 1, auto_load_subclass => 1, auto_create_subclass => 1 },
  Template         => { auto_load_subclass => 1, auto_create_subclass => 1 },
  URI              => { auto_load_subclass => 1 },
);

sub import {
  # "use"ing this module will load or create subclasses in your namespace
  my $caller = caller(0);

  # Load the application's subclassed versions of PlackX::Framework::*
  foreach my $module (keys %modules) {
    my %loaded = ();

    if ($modules{$module}->{auto_load_subclass}) {
      $loaded{$module} = load_subclass($caller, $module);
    }

    # Automatically create any that don't exist, unless auto_create_subclass is false
    if ($modules{$module}->{auto_create_subclass}) {
      generate_subclass($caller . '::' . $module => "PlackX::Framework::$module") unless $loaded{$module};
    }
  }

  export_app_sub($caller);
}

sub export_app_sub {
  my $caller = shift;
  no strict 'refs';
  *{$caller . '::app'} = sub {
    my $class     = shift;
    my $app_class = $class . '::App';
    $app_class->to_app;
  }
}

sub load_subclass {
  my $class   = shift;
  my $module  = shift;
  my $success = eval "require $class\::$module; 1;";
  return $success;
}

sub generate_subclass {
  my ($new_class, $base_class) = @_;

  # Create the package/class - must use string eval
  eval qq{
    package $new_class;
    use $base_class ();
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

A simple PlackX::Framework application could be all in one .psgi file:

    # app.psgi
    package MyProject {
      use PlackX::Framework;  # use, NOT use 'parent'
      use MyProject::Router;  # exports `request', 'request_base', and 'filter'
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

PlackX::Framework has an object-oriented design philosophy that uses both
inheritance and composition to implement its features. Symbols exported are
limited to avoid polluting your namespace, however, a lot of the "magic" is
implemented with the import() method, so be careful about using empty
parenthesis in your use statements. Also be careful about whether you should
`use` a module or `use parent` a module.


=head1 DESCRIPTION

PlackX::Framework consists of the following modules:
PlackX::Framework
PlackX::Framework::App
PlackX::Framework::Request;
PlackX::Framework::Response;
PlackX::Framework::Router;
PlackX::Framework::Router::Engine;
PlackX::Framework::Template;
PlackX::Framework::URI;

The statement "use PlackX::Framework" will automatically find and load all of
the required modules. Then it will look for subclasses of the modules listed 
above that exist in your namespace and load them, or create empty subclasses
for any that do not exist. The following example

    package MyProject {
        use PlackX::Framework;
        # ...app logic here...
    }

will attempt to load MyProject::App, MyProject::Request, MyProject::Response
and so on, or create them if they do not exist.

The PlackX::Framework::Request and PlackX::Framework::Response modules are
subclasses of Plack::Request and Plack::Response sprinkled with additional
features. See the documentation of those modules for details.

The PlackX::Framework::URI module is a subclass URI, enables the additional
methods from URI::QueryParam, and adds some shortcut methods.

The PlackX::Framework::Router::Engine is a subclass of Router::Boom with some
extra convenience methods. Normally, you would not have to use this module
directly. It is used by PlackX::Framework::Router internally.

The PlackX::Framework::Template module can automatically load and set up
Template Toolkit, offering several convenience methods. If you desire to use
a different templating system from TT, you may override as many methods as
necessary in your subclass. A new instance of this class is generated for
each request by the app() method of PlackX::Framework::App.


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


=head2 Databases and Object-Relational Mapping

This framework is databse/ORM agnostic, you are free to choose your own or use
plain DBI/SQL.


=head2 EXPORT

This module will export the method app, which returns the code reference of
your app in accordance to the PSGI specification. (This is actually a shortcut
to ::App->to_app.)


=head1 Dependencies

Plack
URI::Fast
Router::Boom


=head1 SEE ALSO

PSGI
Plack
Plack::Request
Plack::Response


=head1 AUTHOR

Dondi Michael Stroma, E<lt>dstroma@localE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016, 2021 by Dondi Stroma


=cut
