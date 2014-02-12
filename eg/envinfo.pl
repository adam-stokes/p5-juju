#!/usr/bin/env perl

use Mojo::Transaction::WebSocket;
use Mojo::JSON qw(j);
use DDP;

my $endpoint = 'wss://10.0.3.1:17070/';

my $ws = Mojo::Transaction::WebSocket->new(
    remote_address => '10.0.3.1',
    remote_port    => '17070',
    local_address  => '127.0.0.1'
);

$ws->send(
    j({
        "RequestId" => 150,
        "Type"      => "Pinger",
        "Request"   => "Ping",
        "Params"    => {text => "test"}
    })
);
