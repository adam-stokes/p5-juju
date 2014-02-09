package Juju::RPC;
# ABSTRACT: RPC Class

=head1 DESCRIPTION

Contains methods and attributes not meant to be accessed directly but
utilized by the exposed API.

=cut

use Moose;
use Moose::Autobox;
use Mojo::Transaction::WebSocket;
use DDP;

=attr request_id

An incremented ID based on how many requests performed on the connection.

=cut
has 'request_id' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => 0
);

=attr is_authenticated

Stores if user has authenticated with juju api server

=cut
has 'is_authenticated' => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => 0
);

=attr is_connected

Check if a websocket connection exists

=cut
has 'is_connected' => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => 0
);

=attr conn

The websocket connection once connected.

=cut
has 'conn' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => 'Test'
);

=method create_connection

Initiate a websocket connection

=cut
sub create_connection {
    my $self = shift;
    die "Already Connected."
      if $self->is_connected and $self->is_authenticated;
    return Mojo::Transaction::WebSocket->new;
}

=method call

Performs RPC

=head3 Takes

C<params> - Hash of parameters needed to query Juju API

=head3 Returns

C<hash> of results

=cut
sub call {
    my ($self, $params) = @_;
    $params->{RequestId} = $self->request_id;
    $self->request_id += 1;
}


__PACKAGE__->meta->make_immutable;
1;
