#!/usr/bin/env perl

use strict;
use warnings;
use Juju;
use Data::Dumper;

$Data::Dumper::Indent = 1;

my $client = Juju->new(
    endpoint => $ENV{JUJU_ENDPOINT},
    password => $ENV{JUJU_PASS}
);
$client->login;
print Dumper($client->environment_info);
print Dumper($client->status);
$client->close;
