use v5.10;
use strict;
use warnings;

package PlackX::Framework::Template;
use Try::Tiny;

my %template_engine_objects = ();

1;

=pod

SYNOPSIS 

my $tt_object = Template->new(...);
my $response  = Plack::Response->new(...);
PlackX::Framework::Template->new($response);

=cut

sub import {
  my $class   = shift;
  my $options = shift // {};

  # Trap errors
  die "You must import from your app's sublcass of PlackX::Framework::Template, not directly"
    if $class eq __PACKAGE__;

  # Do nothing if get_template_system_object returns something
  return if $class->get_template_engine;

  # By default, setup Template Toolkit
  my $engine;
  my %engine_options = %$options;
  unless (exists $engine_options{'INCLUDE_PATH'}) {
    $engine_options{'INCLUDE_PATH'} = 'template';
  }

  try {
    require Template;
    $engine = Template->new(\%engine_options);
    $class->template_engine($engine);
  } catch {
    warn "Unable to load Template Toolkit: $_[0]";
  };

  return;
}

sub new {
  my $class     = shift;
  my $response  = shift;
  my $templater = shift;
  my $self      = bless {}, $class;

  die 'Usage: ->new($response_object)' unless $response and ref $response;

  unless ($templater) {
    $templater = $class->get_template_engine();
    die 'Not a valid template engine object' unless $templater and ref $templater;
  }

  $self->{template_engine_object} = $templater;
  $self->{response_object} = $response;
  $self->{params} = {};
  $self->{template} = undef;

  return $self;
}

sub get_template_engine {
  return $_[0]->template_engine;
}

sub template_engine {
  my $self  = shift;
  my $class = ref $self ? ref $self : $self;
  $template_engine_objects{$class} = shift if @_;
  return $template_engine_objects{$class};
}

sub param {
  my $self  = shift;
  my $name  = shift;
  $self->{params}{$name} = shift if @_ > 0;
  return $self->{params}{$name};
}

sub add_params {
  my $self   = shift;
  my %params = @_;
  @{$self->{params}}{keys %params} = values %params;
  return $self;
}

*set = \&add_params;

sub use {
  my $self = shift;
  my $tmpl = shift;
  $self->{template} = $tmpl;
}

sub output {
  # This method assumes that template_system_object is a Template Toolkit object
  # or another object with a similar process() method. If your choose a different
  # templating system, you should override this method in your subclass.
  my $self     = shift;
  my $filename = @_ ? shift : $self->{template};

  my $t = $self->{template_engine_object};
  $t->process($filename, $self->{params}, $self->{response_object}) || die 'Unable to process template: ', $t->error, $!;
}

sub render {
  # This method outputs a template and returns the response object in one step
  # (Should it actually be a method of the response object instead?)
  my $self = shift;
  $self->output(@_);
  return $self->{response_object};
}

