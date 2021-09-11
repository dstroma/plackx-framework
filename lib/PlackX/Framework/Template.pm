package PlackX::Framework::Template;

use warnings;
use strict;

1;

=pod

SYNOPSIS 

my $tt_object = Template->new(...);
my $response  = Plack::Response->new(...);
PlackX::Framework::Template->new($response);

=cut

sub new {
  my $class    = shift;
  my $response = shift;
  my $self     = bless {}, $class;

  die 'Usage: ->new($response_object)' unless $response and ref $response;

  my $tso = $class->get_template_system_object();
  die 'Not a valid template system object' unless $tso and ref $tso;

  $self->{template_system_object} = $tso;
  $self->{response_object} = $response;
  $self->{params} = {};
  $self->{template} = undef;

  return $self;
}

sub get_template_system_object {
  die 'Method get_template_system_object() must be implemented by a subclass.';
}
  
sub param {
  my $self  = shift;
  my $name  = shift;
  $self->{params}{$name} = shift if @_ > 0;
  return $self->{params}{$name};
}

sub add_params {
  # Yes, it's identical to set()
  my $self   = shift;
  my %params = @_;
  @{$self->{params}}{keys %params} = values %params;
  return $self;
}

sub set {
  # Yes, it's identical to add_params()
  my $self   = shift;
  my %params = @_;
  @{$self->{params}}{keys %params} = values %params;
  return $self;
}

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
  my $filename = shift || $self->{template};

  my $t = $self->{__template_system_object};
  $t->process($filename, $self->{params}, $self->{response_object}) || die 'Unable to process template: ', $t->error, $!;
}

sub render {
  # This method outputs a template and returns the response object in one step
  # (Should it actually be a method of the response object instead?)
  my $self = shift;
  $self->output(@_);
  return $self->{__response};
}

