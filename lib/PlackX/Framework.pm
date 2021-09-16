package PlackX::Framework;

use 5.010000;
use strict;
use warnings;

use PlackX::Framework::App ();
use PlackX::Framework::Request ();
use PlackX::Framework::Response ();
use PlackX::Framework::Router ();
use PlackX::Framework::Router::Engine ();
use PlackX::Framework::Template ();
use PlackX::Framework::URI ();

our @auto_load   = qw(App Request Response Router Router::Engine URI Template);
our @auto_create = qw(App Request Response Router Router::Engine URI);

sub import {
  # "use"ing this module will load the respective subclasses of your application
  # if they do not exist they will be automatically generated
  my $class  = shift;
  my $caller = caller(0);

  # Load the application's subclassed versions of PlackX::Framework::*
  my $load_success = load_subclasses($caller);

  # Check if loaded; if not, automagically generate the classes
  foreach my $i (@auto_create) {
    unless ($load_success->{$i}) {
      generate_subclass("$caller::$i" => "PlackX::Framework::$i");
    }
  }
}

sub generate_subclass {
  my ($new_class, $base_class) = @_;

  # Create the package/class - must use string eval
  eval qq{
    package $new_class; use $base_class (); use parent '$base_class'; 1;
  } or die $@;

  # Add to %INC so it can be "use"d without looking in the filesystem
  (my $filename = $new_class . '.pm') =~ s{::}{/}g;
  $INC{$filename} = '' unless exists $INC{$filename};
}

sub load_subclasses {
  my $class   = shift;
  my %success = ();
  for my $mod (@auto_load) {
    $success{$mod} = eval "require $class::$mod;";
  }
  return \%success;
}

1;
__END__

=head1 NAME

PlackX::Framework - A thin framework for Plack-based web apps.


=head1 SYNOPSIS

The shortest PlackX::Framework application could be all in one .psgi file:

    # app.psgi
    package MyProject {
      use PlackX::Framework; 
      use MyProject::Router; 
      request '/' => sub {
         my ($request, $response) = @_;
         $response->body('<html><body>Hello World!</body></html>');
         return $response;
      };
    }
    MyProject::App->to_app();

However, normally your application would be laid out with separate modules
in separate files.


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
above and load them, or create empty subclasses for any that do not exist.

The PlackX::Framework::App module supplies the method to_app which 
returns the necessary coderef for inclusion in a .psgi file.

    # Example app.psgi
    use My::Project;
    My::Project::App->to_app();

The PlackX::Framework::Request and PlackX::Framework::Response modules are
subclasses of Plack::Request and Plack::Response sprinkled with additional
features. See the documentation of those modules for details.

The PlackX::Framework::URI module is a subclass of Rose::URI which is offered
for various URI utility functions. (The entire Rose suite is not required to
use this module.)

The PlackX::Framework::Router::Engine is a subclass of Router::Simple with some
extra convenience methods. Normally, you would not have to use this module
directly. It is used by PlackX::Framework::Router internally.

The PlackX::Framework::Template module is a wrapper around (not a subclass of)
Template Toolkit offering several convenience methods. If you desire to use
a different templating system from TT, you may override as many methods as
necessary in your subclass. A new instance of this class is generated for
each request by the app() method of PlackX::Framework::App.


=head2 Routes and Requests

Although PlackX::Framework uses Router::Simple behind the scenes, routing is 
performed in an inline DSL-style. Your controller module must "use" the
associated "::Router" subclass from your project (to avoid collisions between
different apps in the same Perl interpreter). This will export the 'request',
'request_base', and 'filter' functions.

    package My::App::Controller {
      use My::App::Router;
      request '/hello-world' => sub {
        return [200, [], ['Hello World']];
      };
    }

See PlackX::Framework::Router for additional documentation on the DSL-style
request routing.


=head2 Filters

You may decide you want to apply a filter before or after all requests in a 
controller. To do this, use the exported filter function.

    package My::App::Controller;
    use PlackX::Framework::Controller;
    filter 'before' => sub {
        ...
    };
    request '/hello-world' => sub {
        ...
    };
    filter 'after' => sub {
        ...
    };

A before filter should return either a false value, or a reference that is
a response object or PSGI response arrayref. A false value will cause request
processing to proceed as normal, while returning a response will cause that
response to be rendered immediately without moving on to any additional filters
or the main request action.

=head2 EXPORT

None.


=head1 Dependencies

Plack
TAP::Harness::Env (By way of Plack)
Rose::URI
Router::Simple


=head1 SEE ALSO

Plack
Plack::Request
Plack::Response


=head1 AUTHOR

Dondi Michael Stroma, E<lt>dstroma@localE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Dondi Stroma


=cut
