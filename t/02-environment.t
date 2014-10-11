#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

plan skip_all =>
  'must export JUJU_PASS and JUJU_ENDPOINT to enable these tests'
  unless $ENV{JUJU_PASS} && $ENV{JUJU_ENDPOINT};
diag("JUJU Environment tests");

use_ok('Juju');

my $juju_pass     = $ENV{JUJU_PASS};
my $juju_endpoint = $ENV{JUJU_ENDPOINT};

my $juju = Juju->new(endpoint => $juju_endpoint, password => $juju_pass);
$juju->login;

# ENVIRONMENT -----------------------------------------------------------------
$juju->environment_info(
    sub {
        my $val = shift;
        ok(defined($val->{UUID}), "Non block info works.");
    }
);

$juju->client_api_host_ports(
    sub {
        my $val = shift;
        ok(defined($val->{Servers}), "Non block apihosts");
    }
);

$juju->agent_version(
    sub {
        my $val = shift;
        ok(defined($val->{Version}), "Non block agent version");
    }
);

$juju->abort_current_upgrade(
    sub {
        my $val = shift;
        ok(ref($val) eq 'HASH', 'Got a empty hash on abort current upgrade');
    }
);


$juju->status(
    sub {
        my $val = shift;
        ok(defined($val->{Machines}), "non block status works");
    }
);

$juju->get_environment_constraints(
    sub {
        my $val = shift;
        ok(defined($val->{Constraints}), "non block env constraints work");
    }
);

# WATCHERS --------------------------------------------------------------------
$juju->get_watcher(
    sub {
        my $val = shift;
        ok(defined($val->{AllWatcherId}), "non block watchers works");
    }
);

my $watcher = $juju->get_watcher;
$juju->get_watched_tasks(
    $watcher->{AllWatcherId},
    sub {
        my $val = shift;
        ok(defined($val->{Deltas}), "non block watched_tasks works");
    }
);

dies_ok {
    $juju->get_watched_tasks($watcher->{AllWatcherId})
}
"should die as it doesn't run synchronously";

# CHARMS ----------------------------------------------------------------------
my $charm_url = $juju->query_cs('mysql');
ok( defined($charm_url->{charm}->{revision}),
    "Found charm mysql in charm store"
);

$juju->close;
done_testing();
