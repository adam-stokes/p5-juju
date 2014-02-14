package Juju::RPC;
# ABSTRACT: RPC Class

=head1 DESCRIPTION

Contains methods and attributes not meant to be accessed directly but
utilized by the exposed API.

=cut

use Moo;
use namespace::clean;
use AnyEvent;
use AnyEvent::Strict;
use AnyEvent::WebSocket::Client;
use JSON;
use Data::Dumper;
use DDP;

=attr cv

AE::CondVar

=cut
has 'cv' => (is => 'ro', default => sub { AnyEvent->condvar });

=attr conn

Connection object

=cut
has 'conn' => (is => 'rw');

=attr request_id

An incremented ID based on how many requests performed on the connection.

=cut
has 'request_id' => (is => 'rw', default => 0);

=attr is_connected

Check if a websocket connection exists

=cut
has 'is_connected' => (is => 'rw', default => 0);

=method _creation_connection

Initiate a websocket connection and stores itself in C<conn> attribute.

=cut
sub _create_connection {
    my $self = shift;
    die "Already Connected."
      if $self->is_connected and $self->is_authenticated;
    my $client = AnyEvent::WebSocket::Client->new(ssl_no_verify => 1);
    my $conn = $client->connect($self->endpoint)->recv;
    $conn->on(
        each_message => sub {
            my ($connection, $message) = @_;
            my $msg = $message->decoded_body;
            print Dumper(decode_json($msg->{Response}));
        }
    );
    $conn->on(
        finish => sub {
            $self->cv->send;
        }
    );
    # Store connection
    $self->is_connected(1);
    $self->conn($conn);
}

=method close

Closes websocket connection

=cut
sub close {
    my $self = shift;
    $self->conn->close;
    $self->cv->recv;
}

=method call

Sends event to juju api server

=head3 Takes

C<params> - Hash of parameters needed to query Juju API

=head3 Returns

Result of RPC Response

=cut
sub call {
    my ($self, $params, $cb) = @_;
    $self->request_id($self->request_id + 1);
    $params->{RequestId} = $self->request_id;
    $self->conn->send(encode_json($params));
}

1;
