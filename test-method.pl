use v5.38;
use experimental 'class';

package Point {
  sub new ($class, $x, $y) {
    bless { 'x' => $x, 'y' => $y }, $class;
  }
  sub move_right ($self) { $self->{x}++; }
  sub move_left ($self)  { $self->{x}--; }
  sub move_up ($self)    { $self->{y}++; }
  sub move_down ($self)  { $self->{y}--; }
}

class CorinnaPoint {
  field $x :param;
  field $y :param;
  field $_point;

  ADJUST { $_point = Point->new($x, $y); }

  our @delegated_methods = qw(move_right move_left move_up move_down);

  # (eval "method $_ { \$_point->$_ }; 1" or die $@) for @delegated_methods;
  # -> Compile-time error "Field $_point is not accessible outside a method"

  (eval "method $_ { \$self->_point->$_ }; 1" or die $@) for @delegated_methods;
  # -> Works

  method _point {
    $_point
  }

  method describe {
    my $real_x = $_point->{x};
    my $real_y = $_point->{y};
    say "A point at ($real_x, $real_y)";
  }

}

my $p = CorinnaPoint->new('x' => 7, 'y' => 3);
$p->describe;
$p->move_right;
$p->describe;

say $p;
say $p->_point;

our @delegated_methods = qw(move_right move_left move_up move_down);
my $class_defn = q`
class EvalledPoint {
  field $x :param;
  field $y :param;
  field $_point;

  ADJUST { $_point = Point->new($x, $y); }

  method describe {
    my $real_x = $_point->{x};
    my $real_y = $_point->{y};
    say "A point at ($real_x, $real_y)";
  }
`;

$class_defn .= qq`  method $_ { \$_point->$_ }\n` for @delegated_methods;

$class_defn .= "}";


eval $class_defn;


my $p2 = EvalledPoint->new('x' => 10, 'y' => 10);
$p2->describe;
$p2->move_down;
$p2->describe;
say $p2;



