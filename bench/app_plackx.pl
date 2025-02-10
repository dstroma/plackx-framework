#!perl
use v5.40;
package My::App {
  use PlackX::Framework;
  use My::App::Router qw(request);
  request '/:foo' => sub ($request, $response) {
    my $foo = $request->route_param('foo');
    $response->print("Hello from $foo");
    return $response;
  };
}

My::App->app;


