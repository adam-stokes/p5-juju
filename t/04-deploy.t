#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

plan skip_all =>
  'must export JUJU_PASS and JUJU_ENDPOINT to enable these tests'
  unless $ENV{JUJU_PASS} && $ENV{JUJU_ENDPOINT};
diag("JUJU Service Deploy");

use_ok('Juju');

my $juju_pass     = $ENV{JUJU_PASS};
my $juju_endpoint = $ENV{JUJU_ENDPOINT};

my $juju = Juju->new(endpoint => $juju_endpoint, password => $juju_pass);
$juju->login;

dies_ok {
    $juju->deploy
}
'Dies if no charm or service name';

ok($juju->deploy('mysql', 'trusty/mysql'), 'Deploy works');

done_testing();
