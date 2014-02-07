package Juju::Environment;
# ABSTRACT: Exposed juju api environment

use Moose;
use Moose::Autobox;
extends 'Juju::RPC';

=attr endpoint

Websocket address

=cut
has 'endpoint' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { my $self = shift; 'wss://localhost:17070' }
);

=attr username

Juju admin user, this is a tag and should not need changing from the default.

=cut
has 'username' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { my $self = shift; 'user-admin' }
);

=attr password

Password of juju administrator, found in your environments configuration 
under 'admin-secret:'

=cut
has 'password' => (
    is   => 'rw',
    isa  => 'Str',
    lazy => 1
);

__PACKAGE__->meta->make_immutable;
1;
