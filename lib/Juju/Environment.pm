package Juju::Environment;
# ABSTRACT: Exposed juju api environment

use Moo;
extends 'Juju::RPC';
use Data::Dumper;

=attr endpoint

Websocket address

=cut
has 'endpoint' => (is => 'ro', default => sub { 'wss://localhost:17070' });

=attr username

Juju admin user, this is a tag and should not need changing from the default.

=cut
has 'username' => (is => 'ro', default => 'user-admin');

=attr password

Password of juju administrator, found in your environments configuration 
under 'admin-secret:'

=cut
has 'password' => (is => 'rw');

=attr is_authenticated

Stores if user has authenticated with juju api server

=cut
has 'is_authenticated' => (is => 'rw', default => 0);

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
            },
            sub {
                $self->is_authenticated(1);
            }
        );
    }
    #sleep(1);
}

=method info

Return environment information

=head3 Returns

Juju environment state

=cut
sub info {
    my $self = shift;
    $self->call(
        {"Type" => "Client", "Request" => "EnvironmentInfo"},
        sub {
            my $res = shift;
            print Dumper($res);
        }
    );
}

=method add_charm

Add charm

=cut
sub add_charm {
    my ($self, $charm_url) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "AddCharm",
            "Params"  => {"URL" => $charm_url}
        }
    );
}

=method get_charm

Get charm

=cut
sub get_charm {
    my ($self, $charm_url) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "CharmInfo",
            "Params"  => {"CharmURL" => $charm_url}
        }
    );
}

=method get_env_constraints

=cut
sub get_env_constraints {
    my $self = shift;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "GetEnvironmentConstraints"
        }
    );
}

=method set_env_constraints

=cut
sub set_env_constraints {
    my ($self, $constraints) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "SetEnvironmentConstraints",
            "Params"  => $constraints
        }
    );
}

=method get_env_config

=cut
sub get_env_config {
  my $self = shift;
        $self->call({
            "Type"=> "Client",
            "Request"=> "EnvironmentGet"});
}

=method set_env_config

=cut
sub set_env_config {
    my ($self, $config) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "EnvironmentSet",
            "Params"  => {"Config" => $config}
        }
    );
}

1;
