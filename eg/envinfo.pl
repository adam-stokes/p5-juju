#!/usr/bin/env perl

use strict;
use warnings;
use Juju::Environment;
use Mojo::JSON qw(j);
use Data::Dumper;

$Data::Dumper::Indent = 1;

my $client = Juju::Environment->new(
    endpoint => 'wss://10.0.3.1:17070/',
    password => $ENV{'JUJU_PASS'}
    ? $ENV{'JUJU_PASS'}
    : 'bac2d0de80a99bb499c442326a617788'
);
$client->login;
my $_info = $client->info;
print Dumper($_info);

$client->close;
