use v5.40;
package PlackX::Framework::URIx {
  # Since this module is optional, we try to load it during compile-time and
  # fail silently if it doesn't load, replacing new() to raise a fatal error
  BEGIN {
    our $URI_Fast_loaded = eval { require URI::Fast };
    if ($URI_Fast_loaded) {
      eval "use parent 'URI::Fast'";
    } else {
      no strict 'refs';
      *{'new'} = sub { die 'URI::Fast could not be loaded'; };
    }
  }

  sub query_set ($self, @new) {
    foreach my ($key, $val) (@new) {
      $self->param($key => $val);
    }
    return $self;
  }

  sub query_add ($self, @new) {
    foreach my ($key, $val) (@new) {
      $self->add_param($key => $val);
    }
    return $self;
  }

  sub query_delete_all ($self) {
    $self->query_hash({});
    return $self;
  }

  sub query_delete ($self, @names) {
    $self->param($_ => undef) for @names;
    return $self;
  }

  sub query_delete_all_except ($self, @names) {
    my %keep = map { $_ => 1  } @names;
    foreach my $param ($self->query_keys) {
      $self->param($param => undef) unless $keep{$param};
    }
    return $self;
  }

  sub query_delete_keys_starting_with ($self, $string) {
    foreach my $param ($self->query_keys) {
      $self->param($param => undef) if substr($param, 0, length $string) eq $string;
    }
    return $self;
  }

  sub query_delete_keys_ending_with ($self, $string) {
    foreach my $param ($self->query_keys) {
      $self->param($param => undef) if substr($param, 0 - (length $string), length $string) eq $string;
    }
    return $self;
  }

  sub query_delete_keys_matching ($self, $pattern) {
    foreach my $param ($self->query_keys) {
      $self->param($param => undef) if $param =~ m/$pattern/;
    };
    return $self;
  }

  sub query_delete_all_except_keys_matching ($self, $pattern) {
    foreach my $param ($self->query_keys) {
      $self->param($param => undef) unless $param =~ m/$pattern/;
    };
    return $self;
  }
}

=head1 NAME

PlackX::Framework::URIx - Subclass of URI::Fast with extra query string methods


=head1 DESCRIPTION

PlackX::Framework::URIx is part of PlackX::Framework. This module is a subclass
of URI::Fast with extra features for manipulating query strings, namely setting,
adding, or deleting parameters.

If URI::Fast is not installed, this module can still be loaded, but any calls
to new() will die.


=head 2 Rationale

While it is true the URI module does offer URI::QueryParam which can add similar
features, that module was designed to replicate the CGI.pm interface. This one
does not. Method names are shorter and have been chosen to avoid conflicting
with the methods offered by URI::QueryParam. The other distinguishing
characteristic is that all of the added methods return the object so that method
calls may be chained.


=head2 Methods

The following methods are those in addition to the ones contained in the
URI::Fast module.


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

URI::Fast
URI
URI::QueryParam
Rose::URI
