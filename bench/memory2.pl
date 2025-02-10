#!perl
use strict;
use warnings;
use feature 'say';
use Time::HiRes 'time';
use List::Util qw(shuffle);

our %INC0     = %INC;
our %children = ();

my @tests;

push @tests, sub {
	my $fork = fork;
	die "Forking unsuccessful" unless defined $fork;
	$children{'PlackX'} = $fork if $fork;

	if ($fork == 0) {
		my $t0 = time;
		create_pxf_app() or die $@;
		my $t1 = time;
		#say "Loaded for PlackX:\n" . join("\n", grep { $INC0{$_} ? 0 : 1 } keys %INC);
		say "PlackX loaded in " . ($t1 - $t0) . " seconds";
		sleep;
		exit;
	}
};

push @tests, sub {
	my $fork = fork;
	die "Forking unsuccessful" unless defined $fork;
	$children{'Dancer2'} = $fork if $fork;

	if ($fork == 0) {
		my $t0 = time;
		create_d2_app() or die $@;
		my $t1 = time;
		#say "Loaded for Dancer2:\n" . join("\n", grep { $INC0{$_} ? 0 : 1 } keys %INC);
		say "Dancer2 loaded in " . ($t1 - $t0) . " seconds";
		sleep;
		exit;
	}
};

push @tests, sub {
	my $fork = fork;
	die "Forking unsuccessful" unless defined $fork;
	$children{'MojoLite'} = $fork if $fork;

	if ($fork == 0) {
		my $t0 = time;
		create_ml_app() or die $@;
		my $t1 = time;
		#say "Loaded for MojoLite:\n" . join("\n", grep { $INC0{$_} ? 0 : 1 } keys %INC);
		say "MojoLite loaded in " . ($t1 - $t0) . " seconds";
		sleep;
		exit;
	}
};

@tests = shuffle @tests;

foreach my $test (@tests) {
  $test->();
  sleep 1;
}

say "\nChildren started:";
foreach my $key (keys %children) {
  say " - $key: $children{$key}";
}

print "\n\nPress enter to terminate...";
my $inp = <STDIN>;

foreach my $pid (values %children) {
  `kill -9 $pid`;
}
say "Done.";


###############################################################################

sub create_pxf_app {
	eval q`
		package MyApp {
			use PlackX::Framework;
			use MyApp::Router;
			request '/hello-world' => sub {
				my ($request, $response) = @_;
				$response->body('Hello World');
				$response;
			};
			1;
		}
		use HTTP::Server::PSGI;
		my $server = HTTP::Server::PSGI->new(
			host => "localhost",
			port => 9091,
			timeout => 120,
		);
		1;
	`;
}

sub create_d2_app {
	eval q`
		package MyApp {
			use Dancer2;
			get '/' => sub {
				return 'Hello World!';
			};
			1;
		}
	`;
}

sub create_ml_app {
	eval q`
		use Mojolicious::Lite;
		get '/foo' => sub {
			my $c = shift;
			$c->render(text => "Hello from foo.");
		};
		1;
	`;
}


=pod

=head1 RESULTS

Memory usage of a Hello World app:

	PlackX::Framework -  9.3MB
	Dancer2           - 26.7MB
	Mojolicious::Lite - 32.6MB

Load time of the framework and app (fastest time of 5 trials):
	PlackX::Framework - 0.11 seconds
	Dancer2           - 0.44 seconds
	Mojolicious::Lite - 0.42 seconds


