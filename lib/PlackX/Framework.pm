package PlackX::Framework;

use 5.010000;
use strict;
use warnings;

use PlackX::Framework::Request;
use PlackX::Framework::Response;
use PlackX::Framework::Router;
use PlackX::Framework::Template;
use PlackX::Framework::URI;
use PlackX::Framework::App;

sub generate_classes {
  my $self_class   = shift;
  my $wanted_class = shift;
  for my $i (qw/Request Response Router Template URI App Controller/) {
    eval "package $wanted_class\::$i; use $self_class\::$i; use base '$self_class\::$i'; use strict; use warnings; 1;" or die $@;
  }
  return;
}

sub import {
  my $class  = shift;
  my %params = @_;
  if ($params{'generate_classes'}) {
    $class->generate_classes($params{'generate_classes'});
  }
  return;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

PlackX::Framework - A very thin framework for Plack-based web apps.


=head1 SYNOPSIS

TBD.


=head1 DESCRIPTION

TBD.


=head2 EXPORT

None.


=head1 SEE ALSO

Plack
Plack::Request
Plack::Response


=head1 AUTHOR

Dondi Michael Stroma, E<lt>dstroma@localE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Dondi Stroma


=cut
