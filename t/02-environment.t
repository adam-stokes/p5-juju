#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use DDP;

plan skip_all =>
  'must export JUJU_PASS and JUJU_ENDPOINT to enable these tests'
  unless $ENV{JUJU_PASS} && $ENV{JUJU_ENDPOINT};
diag("JUJU Environment tests");

use_ok('Juju');

my $juju_pass = $ENV{JUJU_PASS};
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

my $info = $juju->environment_info;
ok(defined($info->{UUID}), "Blocking info works.");

$juju->status(
    sub {
        my $val = shift;
        ok(defined($val->{Machines}), "non block status works");
    }
);

my $status = $juju->status;
ok(defined($status->{Machines}), "block status works");

$juju->get_env_constraints(
    sub {
        my $val = shift;
        ok(defined($val->{Constraints}), "non block env constraints work");
    }
);
my $env_constraints = $juju->get_env_constraints;
ok(defined($env_constraints->{Constraints}), 'block env constraints work');

# WATCHERS --------------------------------------------------------------------
$juju->get_watcher(
    sub {
        my $val = shift;
        ok(defined($val->{AllWatcherId}), "non block watchers works");
    }

);
my $watcher = $juju->get_watcher;
ok(defined($watcher->{AllWatcherId}), "block watchers work");

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
ok(defined($charm_url->{charm}->{revision}), "Found charm mysql in charm store");

$juju->close;
done_testing();
