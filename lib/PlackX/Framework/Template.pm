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

  $self->{__template_system_object} = $tso;
  $self->{__response} = $response;

  return $self;
}

sub get_template_system_object {
  die 'Method get_template_system_object() must be implemented by a subclass.';
}
  
sub param {
  my $self       = shift;
  my $name       = shift;
  $self->{$name} = shift if scalar @_ > 0;
  return $self->{$name};
}

sub add_params {
  # Yes, it's identical to set()
  my $self   = shift;
  my %params = @_;
  @{$self}{keys %params} = values %params;
  return $self;
}

sub set {
  # Yes, it's identical to add_params()
  my $self   = shift;
  my %params = @_;
  @{$self}{keys %params} = values %params;
  return $self;
}

sub use {
  my $self  = shift;
  my $param = shift;
  $self->{__template_filename} = $param;
}

sub output {
  # This method assumes that template_system_object is a Template Toolkit object
  # or another object with a compatible API. If your choose a different
  # templating system, you should override this method in your subclass.
  my $self     = shift;
  my $filename = shift || $self->{__template_filename};

  my %unblessed_hash = ();
  @unblessed_hash{keys %$self} = values %$self;

  my $tto = $self->{__template_system_object};
  $tto->process($filename, \%unblessed_hash, $self->{__response}) || die 'Unable to process template: ', $tto->error(), $!;
}

sub render {
  my $self = shift;
  $self->output(@_);
  return $self->{__response};
}

