package PlackX::Framework::Filterer;
=nevermind
use strict;
use warnings;

our $filterer;
sub filterer {
  $filterer ||= __PACKAGE__->new;
}

sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;
  return $self;
}

sub add {
  my $self = shift;
  my $spec = shift;
  $self->{filters} ||= {};

  $self->{filters}{$spec->{controller}} ||= [];
  push @{$self->{filters}{$spec->{controller}}}, $spec;
  return $self;
}
