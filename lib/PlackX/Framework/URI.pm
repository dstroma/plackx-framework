use strict;
use warnings;

package PlackX::Framework::URI;
use parent 'URI';
use URI;
use URI::QueryParam;

# Sets or replaces params
sub query_set {
  my $self = shift;
  my %params = @_;
  foreach my $name (keys %params) {
    $self->query_param($name => $params{$name});
  }
  return $self;
}

sub query_add {
  my $self = shift;
  while (my ($name, $value) = (shift, shift)) {
    $self->query_param_append($name => $value);
  }
  return $self;
}

sub query_delete {
  my $self = shift;
  #$self->query_param_delete_via_search(@_) if @_ == 1 and ref $_[0];
  $self->query_param_delete($_) for @_;
  return $self;
}

sub query_delete_all {
	shift->query_delete_all_except();
}

sub query_delete_all_except {
  my $self = shift;
  my %nodelete = map { $_ => 1 } @_;
  foreach my $name ($self->query_param) {
    $self->query_param_delete($name) unless exists $nodelete{$name};
  }
  return $self;
}

sub query_get {
  my $self = shift;
  return $self->query_param(shift);
}

# Removes query parameters starting with 'ajax'
sub query_delete_params_starting_with {
  my $self   = shift;
  my $string = shift;
  foreach my $name ($self->query_param) {
    $self->query_param_delete($name) if substr($name, 0, length $string) eq $string;
  }
  return $self;
}

sub query_delete_params_ending_with {
  my $self   = shift;
  my $string = shift;
  foreach my $name ($self->query_param) {
    $self->query_param_delete($name) if substr($name, 0 - (length $string), length $string) eq $string;
  }
  return $self;
}

1;

