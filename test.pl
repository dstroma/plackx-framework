#!perl

use v5.38;
use experimental 'class';

class Point {

  warn __PACKAGE__;

  field $x :param;
  field $y :param;
  field $sum :param = undef;

  method as_string {
    return "($x, $y)";
  }

  method MOVE_RIGHT {
    $x++;
  }

  sub fake_method ($self) {
    say "fake_method: $self";
    #say $self->x;
  }

  method x {
    $x = shift if @_;
    $x;
  }

  BEGIN {
    use Module::Loaded ();
    Module::Loaded::mark_as_loaded('Point');
  }

  sub import {
    warn "IMPORTING!";
  }
};

package PointX {
  BEGIN {
    use Module::Loaded ();
    Module::Loaded::mark_as_loaded('PointX');
  }
};

my $p = Point->new('x' => 7, 'y' => 3);
say $p->as_string;

$p->MOVE_RIGHT;
say $p->as_string;

say $p;

$p->fake_method;

say "x is " . $p->x;
say "x is " . $p->x();
say "x is " . $p->x(undef);
say "x is " . $p->x;

$p->x(12);

say "x is " . $p->x;
use Point;

######

package MyPackage {
  BEGIN {
    Module::Loaded::mark_as_loaded('MyPackage');
  }
  sub mypackagemethod {
    my $self = shift;
    say $self;
  }
  sub new {
    bless {}, shift;
  }
}

class MyPackage::Subclass {
  our @ISA = 'MyPackage';

}

