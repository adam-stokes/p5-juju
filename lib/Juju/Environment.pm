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

=method _prepare_constraints

Makes sure cpu-cores, cpu-power, mem are integers

=head3 Takes

C<constraints> - hash of service constraints

=head3 Returns

C<constraints> - update constraint hash with any integers set properly.

=cut
sub _prepare_constraints {
    my ($self, $constraints) = @_;
    foreach my $key (keys %{$constraints}) {
        if ($key =~ /cpu-cores|cpu-power|mem/) {
            $constraints->{k} = int($constraints->{k});
        }
    }
    return $constraints;
}



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
    my $svc_constraints;
    if ($constraints) {
        $svc_constraints = $self->_prepare_constraints($constraints);
    }
    $self->call(
        {   "Type"    => "Client",
            "Request" => "ServiceDeploy",
            "Params"  => {
                "ServiceName"   => $service_name,
                "CharmURL"      => $charm_url,
                "NumUnits"      => $num_units,
                "Config"        => $config,
                "Constraints"   => $svc_constraints,
                "ToMachineSpec" => $machine_spec
            }
        }
    );
}

=method set_config

Set's configuration parameters for unit

=head3 Takes

C<service_name> - name of service (ie. blog)

C<config> - hash of config parameters

=cut
sub set_config {
    my ($self, $service_name, $config) = @_;
    die "Not a hash" unless ref $config eq 'HASH';
    return $self->call(
        {   "Type"    => "Client",
            "Request" => "ServiceSet",
            "Params"  => {
                "ServiceName" => $service_name,
                "Options"     => $config
            }
        }
    );
}

=method unset_config

Unsets configuration value for service to restore charm defaults

=head3 Takes

C<service_name> - name of service

C<config_keys> - hash of config keys to unset

=cut
sub unset_config {
    my ($self, $service_name, $config_keys) = @_;
    return $self->call(
        {   "Type"    => "Client",
            "Request" => "ServiceUnset",
            "Params"  => {
                "ServiceName" => $service_name,
                "Options"     => $config_keys
            }
        }
    );
}

=method set_charm

Sets charm url for service

=head3 Takes

C<service_name> - name of service

C<charm_url> - charm location (ie. cs:precise/wordpress)

=cut
sub set_charm {
    my ($self, $service_name, $charm_url, $force) = @_;
    $force = 0 unless $force;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "ServiceSetCharm",
            "Params"  => {
                "ServiceName" => $service_name,
                "CharmUrl"    => $charm_url,
                "Force"       => $force
            }
        }
    );
}

=method get_service

Returns information on charm, config, constraints, service keys.

=head3 Takes

C<service_name> - name of service

=head3 Returns

Hash of information on service

=cut
sub get_service {
    my ($self, $service_name) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "ServiceGet",
            "Params"  => {"ServiceName" => service_name}
        },
        sub { my $res = shift; return $res }
    );
}

=method get_config

Get service configuration

=head3 Takes

C<service_name> - name of service

=head3 Returns

Hash of service configuration

=cut
sub get_config {
    my ($self, $service_name) = @_;
    my $svc = $self->get_service($service_name);
    return $svc->{Config};
}

=method get_constraints

=cut
sub get_constraints {
    my ($self, $service_name) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "GetServiceConstraints",
            "Params"  => {"ServiceName" => $service_name}
        },
        sub {
            my $res = shift;
            return $res->{Constraints};
        }
    );
}

=method set_constraints

=cut
sub set_constraints {
    my ($self, $service_name, $constraints) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "SetServiceConstraints",
            "Params"  => {
                "ServiceName" => $service_name,
                "Constraints" => $self->_prepare_constraints($constraints)
            }
        },
        sub { my $res = shift; return $res }
    );
}

=method update_service

Update a service

=cut
sub update_service {
    my ($self, $service_name, $charm_url, $force_charm_url,
        $min_units, $settings, $constraints)
      = @_;

    $self->call(
        {   "Type"    => "Client",
            "Request" => "SetServiceConstraints",
            "Params"  => {
                "ServiceName"     => $service_name,
                "CharmUrl"        => $charm_url,
                "MinUnits"        => $min_units,
                "SettingsStrings" => $settings,
                "Constraints"     => $self->_prepare_constraints($constraints)
            }
        },
        sub { my $res = shift; return $res }
    );
}

=method destroy_service

Destroys a service

=head3 Takes

C<service_name> - name of service

=cut
sub destroy_service {
    my ($self, $service_name) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "ServiceDestroy",
            "Params"  => {"ServiceName" => $service_name}
        },
        sub { my $res = shift; return $res }
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

=method unexpose

Unexpose service

=cut
sub unexpose {
    my ($self, $service_name) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "ServiceUnexpose",
            "Params"  => {"ServiceName" => $service_name}
        },
        sub { my $res = shift; return $res }
    );
}

=method valid_relation_names

All possible relation names of a service

=cut
sub valid_relation_names {
    my ($self, $service_name) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "ServiceCharmRelations",
            "Params"  => {"ServiceName" => $service_name}
        },
        sub { my $res = shift; return $res }
    );
}

=method add_units

=cut
sub add_units {
    my ($self, $service_name, $num_units) = @_;
    $num_units = 1 unless $num_units;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "AddServiceUnits",
            "Params"  => {
                "ServiceName" => $service_name,
                "NumUnits"    => $num_units
            }
        },
        sub {
            my $res = shift;
            return $res;
        }
    );
}

=method add_unit

=cut
sub add_unit {
    my ($self, $service_name, $machine_spec) = @_;
    $machine_spec = 0 unless $machine_spec;
    my $params = {
        "ServiceName" => $service_name,
        "NumUnits"    => 1
    };

    if ($machine_spec) {
        $params->{ToMachineSpec} = $machine_spec;
    }
    $self->call(
        {   "Type"    => "Client",
            "Request" => "AddServiceUnits",
            "Params"  => $params
        },
        sub { my $res = shift; return $res }
    );
}


=method remove_units

=cut
sub remove_units {
    my ($self, $unit_names) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "DestroyServiceUnits",
            "Params"  => {"UnitNames" => $unit_names}
        },
        sub { my $res = shift; return $res }
    );
}

=method resolved

=cut
sub resolved {
    my ($self, $unit_name, $retry) = @_;
    $retry = 0 unless $retry;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "Resolved",
            "Params"  => {
                "UnitName" => $unit_name,
                "Retry"    => $retry
            }
        },
        sub { my $res = shift; return $res }
    );
}


=method get_public_address

=cut
sub get_public_address {
    my ($self, $target) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "PublicAddress",
            "Params"  => {"Target" => $target}
        },
        sub { my $res = shift; return $res; }
    );
}

=method set_annotation

Set annotations on entity, valid types are C<service>, C<unit>,
C<machine>, C<environment>

=cut
sub set_annotation {
    my ($self, $entity, $entity_type, $annotation) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "SetAnnotations",
            "Params"  => {
                "Tag"   => sprintf("%s-%s", $entity_type, $entity =~ s|/|-|g),
                "Pairs" => $annotation
            }
        },
        sub { my $res = shift; return $res }
    );
}

=method get_annotation

=cut
sub get_annotation {
    my ($self, $entity, $entity_type) = @_;
    $self->call(
        {   "Type"    => "Client",
            "Request" => "GetAnnotations",
            "Params" =>
              {"Tag" => sprintf("%s-%s", $entity_type, $entity =~ s|/|-|g)}
        },
        sub { my $res = shift; return $res }
    );
}

1;
