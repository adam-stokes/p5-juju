package Juju::RPC;
# ABSTRACT: RPC Class

=head1 DESCRIPTION

Contains methods and attributes not meant to be accessed directly but
utilized by the exposed API.

=cut

use Moo;
use namespace::clean;
use AnyEvent;
use AnyEvent::WebSocket::Client;
use JSON;
use Data::Dumper;
use DDP;

=attr cv

AE::CondVar

=cut
has 'cv' => (is => 'ro', default => sub { AnyEvent->condvar });

=attr cb

Current callback for event

=cut
has 'cb' => (is => 'rw');

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

=method creation_connection

Initiate a websocket connection and stores itself in C<conn> attribute.

=head3 Returns

Websocket connection

=cut
sub create_connection {
    my $self = shift;
    die "Already Connected."
      if $self->is_connected and $self->is_authenticated;
    my $client = AnyEvent::WebSocket::Client->new(ssl_no_verify => 1);
    $self->is_connected(1);
    $self->conn($client->connect($self->endpoint)->recv);
}


=method close

Close connection

=cut
sub close {
    my $self = shift;
    $self->conn->close;
}

=method call

Sends event to juju api server

=head3 Takes

C<params> - Hash of parameters needed to query Juju API
C<cb> - (optional) callback routine

=head3 Returns

Result of RPC Response

=cut
sub call {
    my ($self, $params, $cb) = @_;
    my $done = AnyEvent->condvar;

    # Increment request id
    $self->request_id($self->request_id + 1);
    $params->{RequestId} = $self->request_id;
    $self->conn->send(encode_json($params));
    $self->conn->on(
        each_message => sub {
            $done->send(decode_json(pop->decoded_body)->{Response});
        }
    );
    $cb->($done->recv);
}

1;
