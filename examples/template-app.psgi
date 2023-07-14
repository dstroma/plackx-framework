#!perl
use v5.36;
use Module::Loaded ();

package My::Example::App {
	use PlackX::Framework;
}

#######################################################################

package My::Example::App::Controller {
	use My::Example::App::Router;
    use My::Example::App::Template {INCLUDE_PATH => 'examples/template-app/template'};

	# Root request
	request '/' => sub ($request, $response) {
		return $response->template->render('index.phtml');
	};

	# Match request
	request '/user/:username' => sub ($request, $response) {
        $response->template->set('PID' => $$);
		$response->template->param(username => $request->route_param('username'));
		return $response->template->render('user.phtml');
	};

	# List %INC
	request '/INC' => sub ($request, $response) {
		$response->print('<pre>');
		$response->print(join "\n", map { $_ =~ s/\//::/g; $_ =~ s/\.pm$//g; $_ } keys %INC);
		$response->print('</pre>');
		return $response;
	}
}

#######################################################################

My::Example::App->app;
