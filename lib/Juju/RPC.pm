package Juju::RPC;
# ABSTRACT: RPC Class

=head1 DESCRIPTION

Contains methods and attributes not meant to be accessed directly but
utilized by the exposed API.

=cut

use strict;
use warnings;
use AnyEvent;
use AnyEvent::WebSocket::Client;
use JSON::PP;

=attr conn

Connection object

=attr request_id

An incremented ID based on how many requests performed on the connection.

=attr is_connected

Check if a websocket connection exists

=cut
use Class::Tiny qw(conn result is_connected done), {
    request_id => 1,
};


sub BUILD {
    my $self = shift;
    my $client = AnyEvent::WebSocket::Client->new(ssl_no_verify => 1);
    $self->conn($client->connect($self->endpoint)->recv);
    $self->is_connected(1);

    $self->conn->on(
        each_message => sub {
            my ($conn, $message) = @_;
            my $body = decode_json($message->decoded_body);
            if (defined($body->{Response})) {
                $self->done->send($body);
            }
        }
    );
}

=method close

Close connection

=cut
sub close {
    my $self = shift;
    $self->conn->close;
}

=method call ($params, $cb)

Sends event to juju api server, this is the entrypoint for all api calls. If an
B<error> occurs it will return a response object of:

  {
    Error => 'Error message',
    RequestId => 1,
    Response => {}
  }

Otherwise, successful queries will return:

  {
    Response => { some_successful => 'hash' }
    RequestId => 1
  }

=cut
sub call {
    my ($self, $params, $cb) = @_;

    $self->done(AnyEvent->condvar);

    # Increment request id
    $self->request_id($self->request_id + 1);
    $params->{RequestId} = $self->request_id;
    $self->conn->send(encode_json($params));

    # non-blocking
    return $cb->($self->done->recv) if $cb;

    # blocking
    return $self->done->recv;
}

1;
