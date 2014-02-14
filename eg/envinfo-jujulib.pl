#!/usr/bin/env perl

use strict;
use warnings;
use v5.18.0;
use Juju::Environment;
use Mojo::JSON qw(j);
use Data::Dumper;
use DDP;

$Data::Dumper::Indent = 1;

my $client = Juju::Environment->new(endpoint => 'wss://10.0.3.1:17070/');
$client->login('bac2d0de80a99bb499c442326a617788');
$client->info;
$client->close;

