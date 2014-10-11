#!/usr/bin/env perl

use strict;
use warnings;
use Juju::Environment;
use Mojo::JSON qw(j);
use Data::Dumper;

$Data::Dumper::Indent = 1;

my $client = Juju::Environment->new(
    endpoint => $ENV{JUJU_ENDPOINT},
    password => $ENV{JUJU_PASS}
);
$client->login;
print Dumper($client->info);

my $watcher = $client->get_watcher;
print Dumper($watcher);

$client->get_watched_tasks($watcher->{AllWatcherId},
    sub { my $val = shift; print Dumper($val); });
print Dumper($client->status);

$client->close;
