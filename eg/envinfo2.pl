#!/usr/bin/env perl
use strict;
use warnings;
use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::JSON qw(j);

my $params = j(
    {   'Type'      => 'Admin',
        'Request'   => 'Login',
        'RequestId' => 1,
        'Params'    => {
            'AuthTag'  => 'user-admin',
            'Password' => '211fdd69b8942c10cef6cfb8a4748fa4'
        }
    }
);

my $ua = Mojo::UserAgent->new;
$ua->websocket(
    'wss://10.0.3.1:17070' => sub {
        my ($ua, $tx) = @_;
        say 'WebSocket handshake failed!' and return unless $tx->is_websocket;
        $tx->on(
            finish => sub {
                my ($tx, $code, $reason) = @_;
                say "WebSocket closed with status $code.";
            }
        );
        $tx->on(
            message => sub {
                my ($tx, $msg) = @_;
                say "WebSocket message: $msg";
                $tx->finish;
            }
        );
        $tx->send($params);
    }
);
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

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
