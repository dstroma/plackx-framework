use strict;
use warnings;

package PlackX::Framework::URI;
use parent 'URI::Fast';
use URI::Fast ();

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  return $self;
}

sub query_set {
  my $self  = shift;
  my @new   = @_;
  while (@new) {
    my $key = shift @new;
    my $val = shift @new;
    $self->param($key => $val);
  }
  return $self;
}

sub query_add {
  my $self  = shift;
  my @new   = @_;
  while (@new) {
    my $key = shift @new;
    my $val = shift @new;
    $self->add_param($key => $val);
  }
  return $self;
}

sub query_delete_all {
  my $self = shift;
  $self->query_hash({});
  return $self;
}

sub query_delete {
  my $self = shift;
  die 'No parameters specified' unless @_;
  $self->param($_ => undef) for @_;
  return $self;
}

sub query_delete_all_except {
  my $self = shift;
  my %keep = map  { $_ => 1    } @_;
  foreach my $param ($self->query_keys) {
    $self->param($param => undef) unless $keep{$param};
  }
  return $self;
}

sub query_delete_keys_starting_with {
  my $self   = shift;
  my $string = shift;
  foreach my $param ($self->query_keys) {
    $self->param($param => undef) if substr($param, 0, length $string) eq $string;
  }
  return $self;
}

sub query_delete_keys_ending_with {
  my $self   = shift;
  my $string = shift;
  foreach my $param ($self->query_keys) {
    $self->param($param => undef) if substr($param, 0 - (length $string), length $string) eq $string;
  }
  return $self;
}

sub query_delete_keys_matching {
  my $self    = shift;
  my $pattern = shift;
  foreach my $param ($self->query_keys) {
    $self->param($param => undef) if $param =~ m/$pattern/;
  };
  return $self;
}

sub query_delete_all_except_keys_matching {
  my $self    = shift;
  my $pattern = shift;
  foreach my $param ($self->query_keys) {
    $self->param($param => undef) unless $param =~ m/$pattern/;
  };
  return $self;
}

1;

__END__

=head1 NAME

PlackX::Framework::URI - Subclass of URI::Fast with extra query string methods


=head1 DESCRIPTION

PlackX::Framework::URI is part of PlackX::Framework. This module is a subclass
of URI::Fast with extra features for manipulating query strings, namely setting,
adding, or deleting parameters.


=head 2 Rationale

While it is true the URI module does offer URI::QueryParam which can add similar
features, that module was designed to replicate the CGI.pm interface. This one
does not. Method names are shorter and have been chosen to avoid conflicting
with the methods offered by URI::QueryParam. The other distinguishing
characteristic is that all of the added methods return the object so that method
class may be chained.


=head2 Methods

The following methods are those in addition to the ones contained in the
inherited URI class.


=head3 query_set(@pairs)

Adds the list of key-value pairs to the query string. If any keys already exist,
they are removed, even if they key appears more than once in the existing query.
If you would like to preserve existing queys, use query_add instead.
The list must be key-values pairs; no references are accepted.

=head3 query_add(@pairs)

Adds the list of key-value pairs to the query string, even if the respective
keys already exist.

=head3 query_delete(@keys)

Deletes any parameters in the query string named by the list.

=head3 query_delete_all

Deletes all parameters from the query string.

=head3 query_delete_all_except(@keys)

Deletes all parameters from the query string except for the ones named by the
list.

=head3 query_delete_keys_starting_with($string)
=head3 query_delete_keys_ending_with($string)

Deletes any parameters in the query string that start or end (respectively) 
with the string $string.

=head3 query_delete_keys_matching($pattern)
=head3 query_delete_all_except_keys_matching($pattern)

Deletes any parameters in the query string that match or don't match
(respectively) the pattern contained in $pattern.


=head1 EXPORTS

None.

=head1 SEE ALSO

URI
URI::QueryParam
Rose::URI


