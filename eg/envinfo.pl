#!/usr/bin/env perl

use strict;
use warnings;
use v5.14.0;
use AnyEvent;
use AnyEvent::WebSocket::Client;
use Mojo::JSON qw(j);
use Data::Dumper;

$Data::Dumper::Indent = 1;

my $client = AnyEvent::WebSocket::Client->new(ssl_no_verify => 1);

my $params = {
    'Type'      => 'Admin',
    'Request'   => 'Login',
    'RequestId' => '5000',
    'Params'    => {
        'AuthTag'  => 'user-admin',
        'Password' => '211fdd69b8942c10cef6cfb8a4748fa4'
    }
};

my $ws = $client->connect("wss://10.0.3.1:17070/")->recv;
my $done = AnyEvent->condvar;

$ws->on(
    each_message => sub {
      my $msg = pop->decoded_body;
      print Dumper($msg);
      $done->send;
    }
);

$done->recv;
