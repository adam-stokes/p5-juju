#!/usr/bin/env perl

use IO::Async::Loop;
use IO::Socket::SSL;
use Net::Async::WebSocket::Client;
use Mojo::JSON qw(j);

my $HOST = '10.0.3.1';
my $PORT = '17070';

my $params = {
    'Type'      => 'Admin',
    'Request'   => 'Login',
    'RequestId' => 1,
    'Params'    => {
        'AuthTag'  => 'user-admin',
        'Password' => '211fdd69b8942c10cef6cfb8a4748fa4'
    }
};

my $client = Net::Async::WebSocket::Client->new(
    on_frame => sub {
        my ($self, $frame) = @_;
        print $frame;
    },
);

my $loop = IO::Async::Loop->new;
$loop->add($client);
print "starting connection\n";
$client->connect(
    host         => '10.0.3.1',
    service      => '17070',
    url          => "wss://10.0.3.1:17070/",
    on_connected => sub {
        print "we've connected.\n";
        $client->send_frame('hi');
    },

    on_connect_error => sub { die "Cannot connect - $_[-1]" },
    on_resolve_error => sub { die "Cannot resolve - $_[-1]" },
);

print "looping now\n";
$loop->loop_forever;
