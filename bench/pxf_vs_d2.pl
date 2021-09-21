#!perl
use strict;
use warnings;

use Benchmark qw(:all);

cmpthese(10_000_000, {
  'Dancer2' => sub { eval { "use Dancer2;" } },
  'PlackXF' => sub { eval { "use PlackX::Framework;" } },
});

