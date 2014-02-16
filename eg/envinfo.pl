#!/usr/bin/env perl

use strict;
use warnings;
use v5.18.0;
use Juju::Environment;
use Mojo::JSON qw(j);
use Data::Dumper;
use DDP;

$Data::Dumper::Indent = 1;

my $client = Juju::Environment->new(
    endpoint => 'wss://10.0.3.1:17070/',
    password => '211fdd69b8942c10cef6cfb8a4748fa4'
);
$client->login;
my $_info = $client->info;
my $_info2 = $client->info;
my $_info3 = $client->info;
p $_info->{DefaultSeries};
p $_info2->{DefaultSeries};
p $_info3->{UUID};
$client->close;
