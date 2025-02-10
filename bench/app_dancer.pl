#!/usr/bin/env perl
use Dancer2;
get '/:foo' => sub {
    my $foo = route_parameters->get('foo');
    return "Hello from $foo";
};
start;

