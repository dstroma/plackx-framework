#!perl
use v5.36;

package My::Example::App {
	use PlackX::Framework;
}

#######################################################################

package My::Example::App::Util {
	use parent 'Exporter';

	BEGIN {
		our @EXPORT_OK = qw(multitrim);
		$INC{'My/Example/App/Util.pm'} = '/dev/null/My/Example/App/Util.pm';
	}

	use builtin 'trim';
	no warnings 'experimental';

	sub multitrim (@instrings) {
		my @outstrings;
		foreach my $string (@instrings) {
			my @lines = split /\n/, $string;
			@lines = map { trim $_ } @lines;
			$string = join '', @lines;
			push @outstrings, $string;
		}
		return @outstrings;
	}
}

#######################################################################

package My::Example::App::Controller {
	use My::Example::App::Router;
	use My::Example::App::Util qw(multitrim);

	my $app_name    = "My Example App";
	my %credentials = ( username => "joe", password => "schmoe" );

	# Demonstrate a filter
	filter 'after' => sub ($request, $response) {
		# Add signature
		$response->print('<!--Generated by PlackX::Framework My::EXample::App-->');

		# Remove whitespace
		my @body = ref $response->body ? $response->body->@* : $response->body;
		@body = multitrim(@body);
		$response->body(\@body);
		return $response;
	};

	# Root request
	request '/' => sub ($request, $response) {
		my $body = qq{
			<html>
				<head><title>$app_name: Welcome</title></head<
				<body>
					<h1>$app_name</h1>
					<p>Please <a href="/login">Log In</a> to continue.</p>
				</body>
			</html>
		};
		$response->print($body);
		return $response;
	};

	# Different route
	request '/login' => sub ($request, $response) {
		my $message = $request->stash->{'message'} || 'Enter your credentials below.';
		my $body = qq {
			<html>
				<head><title>$app_name: Log In</title></head<
				<body>
					<h1>$app_name: Log In</h1>
					<p>$message</p>
					<form method="post" action="/login/submit">
						<label>Username: <input type="text" name="username"></label>
						<label>Password: <input type="text" name="password"></label>
						<input type="submit" value="Log In">
					</form>
				</body>
			</html>
		};
		$response->print($body);
		return $response;
	};

	# Demonstrate HTTP request method
	request { post => '/login/submit' } => sub ($request, $response) {
		my $username = $request->param('username');
		my $password = $request->param('password');

		unless ($username eq $credentials{'username'} and $password eq $credentials{'password'}) {
			$request->stash->{'message'} = "Incorrect username or password. Try user 'joe' password 'schmoe'.";
			return $request->reroute('/login');
		}
		
		my $body = qq {
			<html>
				<head><title>$app_name: Hello $username</title></head<
				<body>
					<h1>$app_name: Hello $username</h1>
					<p>Welcome back.</p>
				</body>
			</html>
		};
		$response->print($body);
		return $response;
	};

	# Demonstrate string action instead of coderef
	request '/help' => 'help';
	sub help ($request, $response) {
		$response->print('Please call us at 867-5309 for help!');
		return $response;
	}
}

#######################################################################

My::Example::App->app;
