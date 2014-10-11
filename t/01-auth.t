#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use DDP;

plan skip_all =>
  'must export JUJU_PASS and JUJU_ENDPOINT to enable these tests'
  unless $ENV{JUJU_PASS} && $ENV{JUJU_ENDPOINT};
diag("JUJU Authentication");

use_ok('Juju');

my $juju_pass = $ENV{JUJU_PASS};
my $juju_endpoint = $ENV{JUJU_ENDPOINT};

my $juju = Juju->new(endpoint => $juju_endpoint, password => $juju_pass);
ok($juju->isa('Juju'), 'Is juju instance');
$juju->login;
ok($juju->is_authenticated == 1, "Authenticated properly");

done_testing();
