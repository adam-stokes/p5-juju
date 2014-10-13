#!/usr/bin/env perl

use strict;
use warnings;
use Juju;
use DDP;

my $client = Juju->new(
    endpoint => $ENV{JUJU_ENDPOINT},
    password => $ENV{JUJU_PASS}
);
$client->login;
my $status = $client->status;
p $status;

my $machines = [keys %{$status->{Response}->{Machines}}];
p $machines;

# Easily destroy machines
# foreach my $machine (@{$machines}) {
#   if ($machine != 0) {
#     $client->destroy_machines([$machine]);
#   }
# }
$client->close;
