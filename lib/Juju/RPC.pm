package Juju::RPC;
# ABSTRACT: RPC Class

=head1 DESCRIPTION

Contains methods and attributes not meant to be accessed directly but
utilized by the exposed API.

=cut

use Mojo::Base -base;
use Mojo::IOLoop;
use Mojo::UserAgent;
use Mojo::JSON;
use DDP;

=attr json

JSON attribute

=cut
has 'json' => sub { my $self = shift; return Mojo::JSON->new };

=attr ua

UserAgent attribute

=cut
has 'ua' => sub { my $self = shift; return Mojo::UserAgent->new };

=attr conn

The websocket connection

=cut
has 'conn' => '';

=attr counter

Request counter

=cut
has 'counter' => 0;

=attr request_id

An incremented ID based on how many requests performed on the connection.

=cut
has 'request_id' => 0;

=attr is_connected

Check if a websocket connection exists

=cut
has 'is_connected' => 0;

=method create_connection

Initiate a websocket connection

=cut
sub create_connection {
    my $self = shift;
    die "Already Connected."
      if $self->is_connected and $self->is_authenticated;
    $self->conn(
        $self->ua->websocket(
            $self->endpoint => sub {
                my ($ua, $tx) = @_;
                p $tx;
                return unless $tx->is_websocket;
            }
        )
    );
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}

=method close

Closes websocket connection

=cut
sub close {
    my $self = shift;
    $self->conn->finish;
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
    $params->{RequestId} += 1;
    $self->request_id($params->{RequestId});
    $self->conn->on(
        message => sub {
            my ($ws, $msg) = @_;
            return $self->json->decode($msg);
        }
    );
    $self->conn->send({json => $params});
}

1;
