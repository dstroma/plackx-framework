#!perl
use v5.36;

package My::Example::App {
	use PlackX::Framework;
}

#######################################################################

package My::Example::App::Util {
	use builtin 'trim';
	no warnings 'experimental';
	sub multitrim (@instrings) {
		no warnings 'uninitialized';
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

	my $app_name    = "My Example App";
	my %credentials = ( username => "joe", password => "schmoe" );

	my $style = q{
		<style type="text/css">
			body {
				color: #333; font-family: Tahoma, Sans-serif;
				margin: 1em;
			}
			form {
				border: 1px solid #ddd;
				padding: 1em;
			}
			form label {
				display: block;
			}
			form input {
				display: block;
				margin-top: 0.25em;
				margin-bottom: 0.75em;
			}
		</style>
	};

	# Demonstrate a filter - add signature
	filter after => sub ($request, $response) {
		$response->print('<!--Generated by PlackX::Framework My::Example::App-->');
		return $response->continue;
	};

	# Another filter -- remove whitespace
	filter after => sub ($request, $response) {
		my @body = ref $response->body ? $response->body->@* : $response->body;
		@body = My::Example::App::Util::multitrim(@body);
		$response->body(\@body);
		return $response->continue;
	};

	# Root request
	request '/' => sub ($request, $response) {
		my $body = qq{
			<html>
				<head><title>$app_name: Welcome</title>$style</head>
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
				<head><title>$app_name: Log In</title>$style</head>
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
				<head><title>$app_name: Hello $username</title>$style</head>
				<body>
					<h1>$app_name</h1>
					<p>Welcome back, $username.</p>
				</body>
			</html>
		};
		$response->print($body);
		return $response;
	};

	# Demonstrate string action instead of coderef
	request '/help' => 'help';
	sub help ($request, $response) {
		$response->print('Please call us at 867-5309 for help!!!');
		return $response;
	}

	# Demonstrate flash
	request '/flash/set/:message' => sub ($request, $response) {
		$response->flash($request->route_param('message'));
		$response->redirect('/flash/view');
		return $response;
	};
	request '/flash/view' => sub ($request, $response) {
		$response->print($request->flash);
		return $response;
	};
}

#######################################################################

# Routing without DSL
package My::Example::App::Controller::NoDSL {

	My::Example::App::Router->add_route('/nodsl/:pagenum/view' => 'nodsl');

	sub nodsl ($request, $response) {
		my $page = $request->route_param('pagenum');
		$response->print('No DSL!<br>');
		$response->print("You are viewing page $page.<br>\n");
		$response->print("(Note: Filters do not work for this style at the present time.)\n");
		return $response;
	}
}

#######################################################################

my $app = My::Example::App->app;


