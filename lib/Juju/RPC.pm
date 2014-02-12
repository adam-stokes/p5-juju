package Juju::RPC;
# ABSTRACT: RPC Class

=head1 DESCRIPTION

Contains methods and attributes not meant to be accessed directly but
utilized by the exposed API.

=cut

use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::Transaction::WebSocket;
use Mojo::JSON;
use Mojo::URL;
use Mojo::Log;
use DDP;

=attr url

URL

=cut
has 'url' => sub { Mojo::URL->new };

=attr log

LOGGER

=cut
has 'log' => sub { Mojo::Log->new };

=attr json

JSON attribute

=cut
has 'json' => sub { Mojo::JSON->new };

=attr ua

UserAgent attribute

=cut
has 'ua' => sub { Mojo::UserAgent->new };

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

Initiate a websocket connection and stores itself in C<conn> attribute.

=cut
sub create_connection {
    my $self = shift;
    $self->log->debug("Creating websocket connection.");
    my $uri = $self->url->parse($self->endpoint);

    die "Already Connected."
      if $self->is_connected and $self->is_authenticated;
    $self->is_connected(1);
}

=method close

Closes websocket connection

=cut
sub close {
    my $self = shift;
    $self->log->debug("Closing the connection");
    $self->conn->on(
        finish => sub {
            my ($ws, $code, $reason) = @_;
            $self->log->debug("Closed: $reason ($code)");
        }
    );
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
    $self->log->debug('Performing RPC Call');
    $self->request_id($self->request_id + 1);
    $params->{RequestId} = $self->request_id;
    $self->conn->send({json => $params});
}

1;
