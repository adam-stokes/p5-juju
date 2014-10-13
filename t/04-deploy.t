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

$juju->deploy(
    charm        => 'mysql',
    service_name => 'mysql',
    cb           => sub {
        my $val = shift;
        ok(!defined($val->{Error}), "Deployed mysql service");
    }
);
$juju->deploy(
    charm        => 'precise/wordpress',
    service_name => 'wordpress',
    cb           => sub {
        my $val = shift;
        ok(!defined($val->{Error}), "Deployed precise/wordpress service");
    }
);

$juju->add_relation(
    'mysql',
    'wordpress',
    sub {
        my $val = shift;
        ok(defined($val->{Response}->{Endpoints}->{wordpress}), "Found wordpress endpoint relation");
        ok(defined($val->{Response}->{Endpoints}->{mysql}), "Found mysql endpoint relation");
    }
);
done_testing();
