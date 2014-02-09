#!/usr/bin/env perl

use Juju::Environment;
use DDP;

my $env = Juju::Environment->new(endpoint => 'wss://localhost:17070');

my $conn = $env->create_connection;


