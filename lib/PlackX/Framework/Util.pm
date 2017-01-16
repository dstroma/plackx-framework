package PlackX::Framework::Util;

use strict;
use warnings;

sub load_modules {
  my $path = shift;
  require File::Find::Rule;
  my @found = File::Find::Rule->name('*.pm')->in($path);
  foreach my $file (@found) {
    ($file) = $file =~ m|$path/?(.+)\.pm$|;
    $file =~ s|/|::|g;
    eval "require $file" or die "Cannot require $file: $@$!";
  }
}

1;
