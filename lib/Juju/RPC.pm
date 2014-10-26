package Juju::RPC;

# ABSTRACT: RPC Class

=head1 DESCRIPTION

Contains methods and attributes not meant to be accessed directly but
utilized by the exposed API.

=cut

use Moose::Role;
use AnyEvent;
use AnyEvent::WebSocket::Client;
use JSON::PP;
use Function::Parameters;

=attr conn

Connection object

=attr request_id

An incremented ID based on how many requests performed on the connection.

=attr is_connected

Check if a websocket connection exists

=cut
has conn         => (is => 'rw');
has result       => (is => 'rw');
has is_connected => (is => 'rw');
has done         => (is => 'rw');
has request_id   => (is => 'rw', isa => 'Int', default => 1);

method BUILD {
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
method close {
    $self->conn->close;
}

=method call

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

B<Params>

=for :list
* C<params>
Hash of request parameters
* C<cb>
(optional) callback for non-blocking operations

=cut

method call($params, $cb = undef) {
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
