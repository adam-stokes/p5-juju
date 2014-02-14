package Juju::Environment;
# ABSTRACT: Exposed juju api environment

use Moo;
extends 'Juju::RPC';

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

Login to juju

=cut
sub login {
    my $self = shift;
    $self->create_connection unless $self->is_connected;
    $self->call(
        {   "Type"      => "Admin",
            "Request"   => "Login",
            "RequestId" => 10001,
            "Params"    => {
                "AuthTag"  => $self->username,
                "Password" => $self->password
            }
        },
        sub {
            $self->is_authenticated(1);
        }
    );
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
            return $res;
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

=method add_machine

Allocate new machine from the iaas provider (i.e. MAAS)

=head3 Takes

C<series> - OS series (i.e precise)

C<constraints> - machine constraints

C<machine_spec> - not sure yet..

C<parent_id> - not sure yet..

C<container_type> - uh..

Note: Not quite right as I've no idea wtf its doing yet, need to read
the specs.

=cut
sub add_machine {
    my ($self, $series, $constraints, $machine_spec, $parent_id,
        $container_type)
      = @_;
    my $params = {
        "Series"        => $series,
        "Constraints"   => $constraints,
        "ContainerType" => $container_type,
        "ParentId"      => $parent_id,
        "Jobs"          => "",                # TODO: add jobs
    };
    return $self->add_machines([$params])->{Machines}->[0];
}

=method add_machines

Add multiple machines from iaas provider

=head3 Takes

C<machines>

=cut
sub add_machines {
    my ($self, $machines) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "AddMachines",
            "Params"  => {"MachineParams" => $machines}
        }
    );
}

=method register_machine

=method register_machines

=method destroy_machines

=method provisioning_script

=method machine_config

=cut

=method add_relation

Sets a relation between units

=cut
sub add_relation {
    my ($self, $endpoint_a, $endpoint_b) = @_;
    $self->call(
        {   'Type'    => 'Client',
            'Request' => 'AddRelation',
            'Params'  => {'Endpoints' => [$endpoint_a, $endpoint_b]}
        }
    );
}

=method remove_relation

Removes relation between endpoints

=cut
sub remove_relation {
    my ($self, $endpoint_a, $endpoint_b) = @_;
    $self->call(
        {   'Type'    => 'Client',
            'Request' => 'DestroyRelation',
            'Params'  => {'Endpoints' => [$endpoint_a, $endpoint_b]}
        }
    );
}

=method deploy

Deploys a charm to service

=cut
sub deploy {
    my ($self, $service_name, $charm_url, $num_units, $config, $constraints,
        $machine_spec)
      = @_;
    $num_units = 1 unless $num_units;
    my $svc_config      = {};
    my $svc_constraints = {};
    if ($config) {
        $svc_config = $config;
    }
    if ($constraints) {
        $svc_constraints = $constraints;
    }
    $self->call(
        {   "Type"    => "Client",
            "Request" => "ServiceDeploy",
            "Params"  => {
                "ServiceName"   => $service_name,
                "CharmURL"      => $charm_url,
                "NumUnits"      => $num_units,
                "Config"        => $svc_config,
                "Constraints"   => $svc_constraints,
                "ToMachineSpec" => $machine_spec
            }
        }
    );
}

=method expose

Expose service

=cut
sub expose {
    my ($self, $service_name) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "ServiceExpose",
            "Params"  => {"ServiceName" => $service_name}
        }
    );
}

1;
