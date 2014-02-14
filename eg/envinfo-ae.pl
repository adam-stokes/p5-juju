#!/usr/bin/env perl

use strict;
use warnings;
use v5.14.0;
use AnyEvent;
use AnyEvent::WebSocket::Client;
use Mojo::JSON qw(j);
use Data::Dumper;
use DDP;

$Data::Dumper::Indent = 1;

my $client = AnyEvent::WebSocket::Client->new(ssl_no_verify => 1);
my $done = AnyEvent->condvar;

my $params = {
    'Type'      => 'Admin',
    'Request'   => 'Login',
    'Params'    => {
        'AuthTag'  => 'user-admin',
        'Password' => 'bac2d0de80a99bb499c442326a617788'
    }
};

my $ws = $client->connect("wss://10.0.3.1:17070/")->recv;
my $res;
$ws->on(
    each_message => sub {

        # $connection is the same connection object
        # $message isa AnyEvent::WebSocket::Message
        print Dumper(pop->decoded_body);
    }
);

# handle a closed connection...
$ws->on(
    finish => sub {

        # $connection is the same connection object
        my ($connection) = @_;
        $done->send;
    }
);
$ws->send(j($params));
$ws->send(j({"Type" => "Client", "Request" => "EnvironmentInfo"}));
$ws->close;
$done->recv;

