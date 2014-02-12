#!/usr/bin/env perl

use Mojo::UserAgent;

my $password = '211fdd69b8942c10cef6cfb8a4748fa4';
my $endpoint = 'wss://10.0.3.1:17070/';

my $ua = Mojo::UserAgent->new;
$ua->websocket(
    $endpoint => sub {
        my $tx = pop;
        $tx->on(finish => sub { Mojo::IOLoop->stop });
        $tx->on(
            json => sub {
                my ($tx, $msg) = @_;
                say $msg;
            }
        );
        $tx->send('hi');
    }
);
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

