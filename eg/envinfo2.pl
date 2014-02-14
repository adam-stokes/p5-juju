#!/usr/bin/env perl
use strict;
use warnings;
use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::Transaction::WebSocket;
use Mojo::JSON qw(j);
use IO::Socket::SSL;
use Data::Dumper;
BEGIN { $ENV{MOJO_NO_TLS} = 1 }

my $host = '10.0.3.1';
my $port = '17070';
$Data::Dumper::Indent = 1;

my $params = {
    'Type'      => 'Admin',
    'Request'   => 'Login',
    'RequestId' => 5000,
    'Params'    => {
        'AuthTag'  => 'user-admin',
        'Password' => '211fdd69b8942c10cef6cfb8a4748fa4'
    }
};

my $ua = Mojo::UserAgent->new;
$ua->local_address('127.0.0.1');
$ua->websocket(
    'wss://10.0.3.1:17070/' => sub {
        my ($ua, $tx) = @_;
        print Dumper($tx);
        say 'WebSocket handshake failed!' and return unless $tx->is_websocket;
        $tx->on(
            message => sub {
                my ($tx, $msg) = @_;
                print Dumper($msg);
                $tx->finish;
            }
        );
        $tx->send({json => $params});
    }
);
Mojo::IOLoop->start;

__END__

=pod

-- Non-blocking request (https://10.0.3.1:17070)
-- Switching to non-blocking mode
-- Connect (https:10.0.3.1:17070)
-- Client >>> Server (https://10.0.3.1:17070)
GET / HTTP/1.1
Accept-Encoding: gzip
 Connection: Upgrade
Sec-WebSocket-Version: 13
 Host: 10.0.3.1:17070
Content-Length: 0
 Upgrade: websocket
User-Agent: Mojolicious (Perl)
Sec-WebSocket-Key: Mzg2NTk3Mzg1NDg3NjQ3Mg==


-- Client <<< Server (https://10.0.3.1:17070)
H
-- Client <<< Server (https://10.0.3.1:17070)
TTP/1.1 403 Forbidden

=cut
