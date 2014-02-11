package Juju::Environment;
# ABSTRACT: Exposed juju api environment

use Mojo::Base 'Juju::RPC';

=attr endpoint

Websocket address

=cut
has 'endpoint' => 'wss://localhost:17070';

=attr username

Juju admin user, this is a tag and should not need changing from the default.

=cut
has 'username' => 'user-admin';

=attr password

Password of juju administrator, found in your environments configuration 
under 'admin-secret:'

=cut
has 'password' => '';

=attr is_authenticated

Stores if user has authenticated with juju api server

=cut
has 'is_authenticated' => 0;

=method login

Login to juju api server

=head3 Takes

C<password> - Password of Juju API Server

=cut
sub login {
    my ($self, $password) = @_;

    # Store for additional authenticated connections
    $self->password($password);
    if (!$self->is_authenticated) {
        $self->call(
            {   "Type"    => "Admin",
                "Request" => "Login",
                "Params"  => {
                    "AuthTag"  => $self->username,
                    "Password" => $self->password
                }
            }
        );
    }
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

1;
