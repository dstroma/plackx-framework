#!perl
use strict;
use warnings;
use feature 'say';

{
	my $fork = fork;
	die "Forking unsuccessful" unless defined $fork;

	if ($fork == 0) {
		say "PlackX::Framework Fork: $$";
		create_pxf_app();
		sleep 60;
		exit;
	}
}

{
	my $fork = fork;
	die "Forking unsuccessful" unless defined $fork;

	if ($fork == 0) {
		say "Dancer2 Fork: $$";
		create_d2_app();
		sleep 60;
		exit;
	}
}

{
	my $fork = fork;
	die "Forking unsuccessful" unless defined $fork;

	if ($fork == 0) {
		say "Mojolicious::Lite Fork: $$";
		create_ml_app();
		sleep 60;
		exit;
	}
}

sub create_pxf_app {
	eval q(
		package MyApp {
			use PlackX::Framework;
			use MyApp::Router;
			request '/hello-world' => sub {
				my ($request, $response) = @_;
				$response->body('Hello World');
				$response;
			};
		}
	);
}

sub create_d2_app {
	eval q(
		package MyApp {
			use Dancer2;
			get '/' => sub {
				return 'Hello World!';
			};
		}
	);
}

sub create_ml_app {
	eval q|
		use Mojolicious::Lite;
		get '/:foo' => sub {
			my $c = shift;
			my $foo = $c->param('foo');
			$c->render(text => "Hello from $foo.");
		};	 
	|;
}


=pod

=head1 RESULTS

Memory usage of a Hello World app:

	PlackX::Framework -  9.3MB
	Dancer2           - 26.7MB
	Mojolicious::Lite - 32.6MB


