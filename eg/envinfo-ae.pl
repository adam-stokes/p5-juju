#!/usr/bin/env perl

use strict;
use warnings;
use v5.14.0;
use AnyEvent;
use AnyEvent::WebSocket::Client;
use JSON::PP;
use DDP;

my $client = AnyEvent::WebSocket::Client->new(ssl_no_verify => 1);

my $params = {
    'Type'      => 'Admin',
    'Request'   => 'Login',
    'Params'    => {
        'AuthTag'  => 'user-admin',
        'Password' => $ENV{JUJU_PASS}
    }
};

my $ws = $client->connect("wss://localhost:17070/")->recv;
my $res;
$ws->on(
    each_message => sub {
      my ($c, $m) = @_;
        # $connection is the same connection object
        # $message isa AnyEvent::WebSocket::Message
        $done->send(decode_json($m->decoded_body));
    }
);

my $done = AnyEvent->condvar;
$ws->send(encode_json($params));
p($done->recv);

$done = AnyEvent->condvar;
$ws->send(encode_json({"Type" => "Client", "Request" => "FullStatus"}));
p($done->recv);

$ws->close;

