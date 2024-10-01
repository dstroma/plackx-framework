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
    filter 'before' => sub { $My::Test::Controller::somevar = 16; return; };
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
  ok($somevar == 16);

  # Route with params
  $env->{PATH_INFO} = $env->{SCRIPT_NAME} = '/app/article/255';
  $match = My::Test::Controller::Router->engine->match(PlackX::Framework::Request->new($env));
  ok($match && $match->{'article'} eq '255');

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
