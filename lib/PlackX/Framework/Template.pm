package PlackX::Framework::Template;

use warnings;
use strict;

1;

=pod

SYNOPSIS 

my $tt_object = Template->new(...);
my $response  = Plack::Response->new(...);
PlackX::Framework::Template->new($tt_object, $response);

=cut

sub new {
  my $class    = shift;
  my $tto      = shift;
  my $response = shift;
  my $self     = bless {}, $class;

  die 'Usage: ->new($template_toolkit_object, $response_object' unless $tto and $response and ref $tto and ref $response;

  $self->{__template_toolkit_object} = $tto;
  $self->{__response} = $response;

  return $self;
}
  
sub param {
  my $self       = shift;
  my $name       = shift;
  $self->{$name} = shift if scalar @_ > 0;
  return $self->{$name};
}

sub add_params {
  my $self   = shift;
  my %params = @_;
  @{$self}{keys %params} = values %params;
  return $self;
}
*set = \&add_params;

sub use {
  my $self  = shift;
  my $param = shift;
  $self->{__template_filename} = $param;
}

sub output {
  my $self     = shift;
  my $filename = shift || $self->{__template_filename};

  my %unblessed_hash = ();
  @unblessed_hash{keys %$self} = values %$self;

  my $tto = $self->{__template_toolkit_object};
  $tto->process($filename, \%unblessed_hash, $self->{__response}) || die 'Unable to process template: ', $tto->error(), $!;
}

sub render {
  my $self = shift;
  $self->output(@_);
  return $self->{__response};
}

