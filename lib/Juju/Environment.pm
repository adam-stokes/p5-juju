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
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => 'hohoho'
);

sub BUILD {
  my $self = shift;
  $self->create_connection unless $self->conn;
}

=method login

Login to juju api server

=head3 Takes

C<password> - Password of Juju API Server
C<username> - (optional, default: 'user-admin') Username

=cut
sub login {
    my ($self, $password, $username) = @_;

    # Store for additional authenticated connections
    $self->username($username);
    $self->password($password);
    $self->call(
        {   "Type"    => "Admin",
            "Request" => "Login",
            "Params"  => {"AuthTag" => $username, "Password" => $password}
        }
    );
    $self->is_authenticated(1);
}

=method info

Return environment information

=head3 Returns

Juju environment state

=cut
sub info {
    my $self = shift;
    return $self->call({"Type" => "Client", "Request" => "EnvironmentInfo"});
}

__PACKAGE__->meta->make_immutable;
1;
