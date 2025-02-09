use v5.10;
use strict;
use warnings;

use Test::More;
use Try::Tiny;
use feature 'say';
our $verbose = 0;

my $uri_fast_available = try {
	require URI::Fast;
	1;
};

if ($uri_fast_available) {
	run_tests('PlackX::Framework::URIx');
} else {
	use_ok('PlackX::Framework::URIx');
	my $new_ok = try {
		my $uri = PlackX::Framework::URIx->new('http://www.google.com/');
		1;
	};
	ok(!$new_ok, 'URI::Fast not available, so new() causes fatal error');
}

done_testing();

sub run_tests {
	my $class = shift;

	use_ok($class);

	my $uri = $class->new('http://www.google.com/?search=xxx');
	ok($uri, 'Successfully call method new()');
	ok(ref $uri && $uri->isa($class), 'Got an object');

	$uri->query_set(search => 'best linux distro');
	ok($uri !~ m/xxx/ && $uri =~ m/best(\+|\%20)linux(\+|\%20)distro/, 'Old params should be overwritten by query_set');
	say $uri if $verbose;

	$uri->query_add(search => 'perl');
	ok($uri =~ m/search=best(\+|\%20)linux(\+|\%20)distro/ && $uri =~ m/search=perl/, 'Old params should be kept and new added by query_add');
	say $uri if $verbose;

	$uri->query_delete_all();
	ok($uri !~ m/search/ && $uri !~ m/perl/, 'All params should be deleted by query_delete_all');
	say $uri if $verbose;

	$uri->query_add(param1 => 'one', param2 => 'two');
	ok($uri =~ m/param1/ && $uri =~ m/param2/ && $uri =~ m/one/ && $uri =~ m/two/, 'Can add multiple params at once');
	say $uri if $verbose;

	$uri->query_delete_all();
	$uri->query_set(param_a => 'apple', param_b => 'banana');
	ok($uri =~ m/param_a=apple/ && $uri =~ m/param_b=banana/, 'Can set multiple params at once');
	say $uri if $verbose;

	$uri->query_delete('param_b', 'blah');
	ok($uri !~ m/param_b/ && $uri =~ m/param_a/ && $uri !~ m/blah/, 'Delete a single param');
	say $uri if $verbose;

	$uri = $class->new('http://www.google.com/?car=edsel&cart=shopping&carnival=fun&art=painting&val=value');
	$uri->query_delete_keys_starting_with('car');
	ok($uri !~ m/car/ && $uri !~ m/carnival/ && $uri !~ m/cart/ && $uri =~ m/art=painting/ && $uri =~ m/val=value/, 'Delete values starting with a string');
	say $uri if $verbose;
}

__END__

sub ok     { }
sub use_ok { eval "require $_[0];" or die $! }

use Benchmark qw(cmpthese);
cmpthese(10_000, {
  slow => sub { test('PlackX::Framework::URI::Standard') },
  fast => sub { test('PlackX::Framework::URI::Fast')     },
});

done_testing();


