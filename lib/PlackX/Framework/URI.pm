use strict;
use warnings;

package PlackX::Framework::URI;
use parent 'URI';

use URI;
use URI::QueryParam;

# Sets or replaces params
sub set {
  my $self = shift;
  my %params = @_;
  foreach my $name (keys %params) {
    $self->query_param($name => $params{$name});
  }
  return $self;
}

sub add {
  my $self = shift;
  while (my ($name, $value) = (shift, shift)) {
    $self->query_param_append($name => $value);
  }
  return $self;
}

sub delete {
  my $self = shift;
  $self->query_param_delete($_) for @_;
  return $self;
}

sub delete_all_except {
  my $self = shift;
  my %nodelete = map { $_ => 1 } @_;
  foreach my $name ($self->query_param) {
    $self->query_param_delete($name) unless exists $nodelete{$name};
  }
  return $self;
}

sub get {
  my $self = shift;
  return $self->query_param(shift);
}

# Removes query parameters starting with 'ajax'
sub delete_if_starts_with {
  my $self   = shift;
  my $string = shift;
  foreach my $name ($self->query_param) {
    $self->query_param_delete($name) if substr($name, 0, length $string) eq $string;
  }
  return $self;
}

sub delete_if_ends_with {
  my $self   = shift;
  my $string = shift;
  foreach my $name ($self->query_param) {
    $self->query_param_delete($name) if substr($name, 0 - (length $string), length $string) eq $string;
  }
  return $self;
}

1;

