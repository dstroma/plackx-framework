use v5.36;
package PlackX::Framework::URIx {
  use parent 'URI::Fast';
  use Scalar::Util qw(blessed);
  use URI ();
  use URI::Escape ();

  # new_from_pxfrequest
  # SUBROUTINE COPIED FROM PLACK::REQUEST AND MODIFIED FOR PLACKX::FRAMEWORK
  sub new_from_pxfrequest ($class, $requ) {
    my $base = $requ->_uri_base;

    # PXF MODIFICATION
    # We can't use $requ->env->{PATH_INFO} in case the request has been rerouted
    # with $request->reroute(...), and we also can't use ->destination() as-is
    # because PXF::Handler might have modified it to remove the app uri_prefix
    my $path_info;
    {
      my $removed_prefix = defined $requ->{removed_prefix} ? $requ->{removed_prefix} : '';
      my $destination    = $requ->destination;
      $path_info         = $removed_prefix . $destination;
    }
    # END PXF MODIFICATION

    # We have to escape back PATH_INFO in case they include stuff like
    # ? or # so that the URI parser won't be tricked. However we should
    # preserve '/' since encoding them into %2f doesn't make sense.
    # This means when a request like /foo%2fbar comes in, we recognize
    # it as /foo/bar which is not ideal, but that's how the PSGI PATH_INFO
    # spec goes and we can't do anything about it. See PSGI::FAQ for details.

    # See RFC 3986 before modifying.
    my $path_escape_class = q{^/;:@&=A-Za-z0-9\$_.+!*'(),-};

#   my $path = URI::Escape::uri_escape($requ->env->{PATH_INFO} || '', $path_escape_class); # ORIGINAL
    my $path = URI::Escape::uri_escape($path_info              || '', $path_escape_class); # PXF MODIFICATION
    $path .= '?' . $requ->env->{QUERY_STRING}
        if defined $requ->env->{QUERY_STRING} && $requ->env->{QUERY_STRING} ne '';

    $base =~ s!/$!! if $path =~ m!^/!;

    return $class->new($base . $path)->normalize;
  }


  # The below line causes a buffer overflow on github!
  # URI::Fast->new('other.html')->absolute('http://www.somewebsite.com/somedir/somewhere');
  # So to() uses URI.pm instead of URI::Fast
  # Continue to use URI::Fast elsewhere, because
  #  - it is faster
  #  - it has more methods for query string manipulation than URI.pm
  #  - URI.pm is a pain to subclass, returning objects blessed into different
  #    classes depending on the argument

  sub goto ($self, $rel) {
    die 'Object method called as class method' unless ref $self;
    my $new = URI->new_abs("$rel", "$self");
    return (ref $self)->new("$new");
  }

  sub goto_with_query ($self, $rel) {
    my $new = $self->goto($rel);
    $new->query(scalar $self->query);
    return $new;
  }

  sub query_set ($self, @new) {
    while (@new) {
      my $key = shift @new;
      my $val = shift @new;
      $self->param($key => $val);
    }
    return $self;
  }

  sub query_add ($self, @new) {
    while (@new) {
      my $key = shift @new;
      my $val = shift @new;
      $self->add_param($key => $val);
    }
    return $self;
  }

  sub query_delete ($self, @keys) { $self->param($_ => undef) for @keys; $self }
  sub query_delete_all ($self)    { $self->query_hash({}); $self }

  sub query_delete_all_except ($self, @keys) {
    my %keep = map { $_ => 1  } @keys;
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

1;

=head1 NAME

PlackX::Framework::URIx - Extended URI class.


=head1 DESCRIPTION

PlackX::Framework::URIx is part of PlackX::Framework. This module is a subclass
of URI::Fast with extra features for manipulating query strings, namely setting,
adding, or deleting parameters; and creating absolute URLs from relative ones.


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

=over 4

=item URI::Fast

=item URI

=item URI::QueryParam

=item Rose::URI
