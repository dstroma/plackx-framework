package PlackX::Framework::URI;

use parent 'Rose::URI';

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
    $self->query_param_add($name => $value);
  }
  return $self;
}

sub delete {
  my $self = shift;
  $self->query_param_delete(@_);
  return $self;
}

sub delete_all_except {
  my $self = shift;
  my @nodelete = @_;
  my %nodelete = map { $_ => 1 } @nodelete;
  foreach my $name (keys %{$self->query_hash}) {
    $uri->query_param_delete($name) unless exists $nodelete{$name};
  }
  return $self;
}

sub get {
  my $self = shift;
  $self->query_param(shift);
  return $self;
}

# Removes query parameters starting with 'ajax'
sub clean_ajax {
  my $self = shift;
  foreach my $name (keys %{$self->query_hash}) {
    $self->delete($name) if substr($name, 0, 4) eq 'ajax';
  }
  return $self;
}

1;

