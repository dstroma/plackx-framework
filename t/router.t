#!perl
use v5.40;

package My::Test::Controller {
  use Test::More;

  # Require
  require_ok('PlackX::Framework::Router');

  # Set up basic ap
  use PlackX::Framework;
  use My::Test::Controller::Router;

  our $somevar;

  # Routes
  ok(eval q{
    filter 'before' => sub { $My::Test::Controller::somevar = $$; return; };
    request '/home' => sub { };
    request_base '/app';
    request '/article/:article' => sub { };
    1;
  });

  # Invalid
  ok(not eval q{
    no warnings;
    before_filter 'blah' => sub { };
    1;
  });

  # Invalid
  ok(not eval q{
    no warnings;
    get '/url' => sub { };
    1;
  });

  # Test routes and Filters
  # Bad route
  my $env = main::sample_env();
  my $match = My::Test::Controller::Router->engine->match(PlackX::Framework::Request->new($env));
  ok(not $match);

  # Good Route
  $env->{PATH_INFO} = $env->{SCRIPT_NAME} = '/home';
  $match = My::Test::Controller::Router->engine->match(PlackX::Framework::Request->new($env));
  ok($match);

  # Test Filter
  ok($match->{prefilters}[0] and ref $match->{prefilters}[0]{action} eq 'CODE');
  ok(not $match->{prefilters}[0]{action}->());
  ok($somevar == $$);

  # Route with params
  $env->{PATH_INFO} = $env->{SCRIPT_NAME} = '/app/article/255';
  $match = My::Test::Controller::Router->engine->match(PlackX::Framework::Request->new($env));
  ok($match && $match->{'article'} eq '255');

  # Method call routes
  My::Test::Controller::Router->add_route('/class-method/:param', sub { });
  $env->{PATH_INFO} = $env->{SCRIPT_NAME} = '/class-method/argument';
  $match = My::Test::Controller::Router->engine->match(PlackX::Framework::Request->new($env));
  ok($match && $match->{'param'} eq 'argument');

  # Method call route with base
  My::Test::Controller::Router->add_route('/another-method/:param', sub { }, base => '/basic/');
  $env->{PATH_INFO} = $env->{SCRIPT_NAME} = '/basic/another-method/debate';
  $match = My::Test::Controller::Router->engine->match(PlackX::Framework::Request->new($env));
  ok($match && $match->{'param'} eq 'debate');

  # Method call with filter
  My::Test::Controller::Router->add_route('/class-filter', sub { }, filter => { before => sub { $$*2; } });
  $env->{PATH_INFO} = $env->{SCRIPT_NAME} = '/class-filter';
  $match = My::Test::Controller::Router->engine->match(PlackX::Framework::Request->new($env));
  ok($match && $match->{prefilters} && $match->{prefilters}[0]->() == $$*2);

  # Method call with after filter
  My::Test::Controller::Router->add_route('/class-filter', sub { }, filters => { after => [sub { $$*3; }] });
  $env->{PATH_INFO} = $env->{SCRIPT_NAME} = '/class-filter';
  $match = My::Test::Controller::Router->engine->match(PlackX::Framework::Request->new($env));
  ok($match && $match->{postfilters} && $match->{postfilters}[0]->() == $$*3);


  done_testing();
}

sub sample_env {
  return {
    REQUEST_METHOD    => 'GET',
    SERVER_PROTOCOL   => 'HTTP/1.1',
    SERVER_PORT       => 80,
    SERVER_NAME       => 'example.com',
    SCRIPT_NAME       => '/foo',
    REMOTE_ADDR       => '127.0.0.1',
    PATH_INFO         => '/foo',
    'psgi.version'    => [ 1, 0 ],
    'psgi.input'      => undef,
    'psgi.errors'     => undef,
    'psgi.url_scheme' => 'http',
  }
};
