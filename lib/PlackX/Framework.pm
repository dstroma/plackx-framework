package PlackX::Framework;

use 5.010000;
use strict;
use warnings;

use PlackX::Framework::App ();
use PlackX::Framework::Request ();
use PlackX::Framework::Response ();
use PlackX::Framework::Router ();
use PlackX::Framework::Template ();
use PlackX::Framework::URI ();
use PlackX::Framework::Controller ();

our @children = qw/App Request Response Router Template URI Controller/;

sub import {
  # using this module will load your application's appropriate modules;
  # if they do not exist they will be automatically generated
  my $class  = shift;
  my $caller = caller(0);

  # Load the modules
  my $load_success = load_framework($caller);

  # Special Case - FORCE creation of Controller so that we can import properly
  $load_success->{Controller} = undef;

  # Check if loaded; if not, automagically generate the classes
  foreach my $i (@children) {
    unless ($load_success->{$i}) {
      generate_class("$caller::$i" => "PlackX::Framework::$i");
    }
  }
}

sub generate_class {
  my ($new_class, $base_class) = @_;
  eval "package $new_class; use parent '$base_class'; use $base_class; 1;" or die $@; 
}

sub load_framework {
  my $class   = shift;
  my %success = ();
  for my $mod (@children) {
    $success{$mod} = eval "require $class::$mod;";
  }
  return \%success;
}

#our %allowed_modules_for_subclass_generator = (
#  App => 1,
#  Router => 1,
#  Request => 1,
#  Response => 1,
#  Template => 1,
#  URI => 1,
#  Controller => 1,
#);
#
#sub import {
#  my $class  = shift;
#  my %params = @_;
#  if ($params{'autogen'}) {
#    my @modules_to_generate;
#    if (ref $params{'autogen'}) {
#      @modules_to_generate = @{$params{'autogen'}};
#    } else {
#      @modules_to_generate = ($params{'autogen'});
#    }
#    $class->gen_subclasses(@modules_to_generate);
#  }
#  $class->load_framework;
#}
#
#sub gen_subclasses {
#  my $class   = shift;
#  my $modules = shift;
#
#  if ($modules and not ref $modules and $modules eq ':all') {
#    $modules = [ keys %allowed_modules_for_subclass_generator ];
#  }
#
#  for my $i (@$modules) {
#    eval "package $class::$i; use parent 'PlackX::Framework::$i'; 1;" or die $@;
#  }
#}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

PlackX::Framework - A very thin framework for Plack-based web apps.


=head1 SYNOPSIS

The shortest PlackX::Framework application could be all in one .psgi file:

    # app.psgi
    package MyProject;
    use PlackX::Framework;
    PlackX::Framework->generate_sublcasses(qw/:all/);

    package MyProject::Controller::HelloWorld;
    use MyProject::Controller;
    request '/' => sub {
         # hello
    };

    package main;
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
PlackX::Framework::Template;
PlackX::Framework::URI;
PlackX::Framework::Controller ();

The base PlackX::Framework module loads all of the required modules. It
also allows your base application module to automatically generate all
the necessary subclasses of PlackX::Framework's modules automatically.

    # Example 1: Generate all subclasses
    package My::Project;
    use PlackX::Framework;
    PlackX::Framework->generate_sublcasses(qw/:all/);

    # Example 2: Generate just the subclasses you want
    package My::Project;
    use PlackX::Framework;
    PlackX::Framework->generate_sublcasses(qw/App Request Response Template URI/);

The PlackX::Framework::App module supplies to methods, app and to_app which 
returns the necessary coderef for inclusiong in a .psgi file.

    # Example application base class
    package My::Project;
    use PlackX::Framework;
    PlackX::Framework->generate_sublcasses(qw/:all/); # Generates My::Project::App, among others.

    # Example app.psgi
    use My::Project;
    My::Project::App->to_app();

The PlackX::Framework::Request and PlackX::Framework::Response modules are
subclasses of Plack::Request and Plack::Response sprinkled with additional
features. See the documentation of those modules for details.

The PlackX::Framework::URI module is a subclass of Rose::URI which is offered
for various URI utility functions. (The entire Rose suite is not required to
use this module.)

The PlackX::Framework::Router is a subclass of Router::Simple with an extra
convenience method called add_route. Normally, you would not have to use 
this module directly. It is used by PlackX::Framework::Controller internally.

The PlackX::Framework::Template module is a wrapper around (not a baseclass of)
Template Toolkit offering several convenience methods. If you desire to use
a different templating system from TT, you may override as many methods as
necessary in your subclass. A new instance of this class is generated for
each request by the app() method of PlackX::Framework::App.


=head2 Routes and Requests

Although PlackX::Framework uses Router::Simple behind the scenes, routing is 
performed in an inline DSL-style. Your controller must use PlackX::Controller 
or preferably a subclass thereof. This exports the request function as well
as the filter function. 

    package My::App::Controller;
    use PlackX::Framework::Controller;
    request '/hello-world' => sub {
        my $response = [200, [], ['Hello World']];
        return $response;
    };

See PlackX::Framework::Controller for additional documentation on the request
function.

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

If a before filter returns any true value that is a reference, it is assumed 
to be a Plack/PSGI response and is returned to the app. The appropriate 
controller action is not called. If a before filter returns any other value 
(it is recommended your return a false value for future-proofing), request 
processing is continued by calling the appropriate controller action as 
normal.


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
