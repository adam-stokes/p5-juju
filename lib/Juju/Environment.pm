package Juju::Environment;

# ABSTRACT: Exposed juju api environment

=head1 SYNOPSIS

  use Juju;

  my $juju = Juju->new(endpoint => 'wss://localhost:17070', password => 's3cr3t');

=cut

use strict;
use warnings;
use JSON::PP;
use YAML::Tiny qw(Dump);
use Data::Validate::Type qw(:boolean_tests);
use Params::Validate qw(:all);
use Juju::Util;
use parent 'Juju::RPC';

=attr endpoint

Websocket address

=attr username

Juju admin user, this is a tag and should not need changing from the
default.

B<Note> This will be changing once multiple user support is released.

=attr password

Password of juju administrator, found in your environments configuration
under B<password>

=attr is_authenticated

Stores if user has authenticated with juju api server

=attr Jobs

Supported juju jobs

=cut

use Class::Tiny qw(password is_authenticated), {
    endpoint => sub {'wss://localhost:17070'},
    username => sub {'user-admin'},
    Jobs     => sub {
        {   HostUnits     => 'JobHostUnits',
            ManageEnviron => 'JobManageEnviron',
            ManageState   => 'JobManageSate'
        };
    },
    util   => Juju::Util->new
};


=method _prepare_constraints ($constraints)

Makes sure cpu-cores, cpu-power, mem are integers

C<constraints> - hash of service constraints

=cut

sub _prepare_constraints {
    my ($self, $constraints) = @_;
    foreach my $key (keys %{$constraints}) {
        if ($key =~ /^(cpu-cores|cpu-power|mem|root-disk)/) {
            $constraints->{k} = int($constraints->{k});
        }
    }
    return $constraints;
}

=method login

Login to juju, will die on a failed login attempt.

=cut

sub login {
    my $self = shift;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

    my $params = {
        "Type"      => "Admin",
        "Request"   => "Login",
        "RequestId" => $self->request_id,
        "Params"    => {
            "AuthTag"  => $self->username,
            "Password" => $self->password
        }
    };

    # block
    my $res = $self->call($params);
    die $res->{Error} if defined($res->{Error});
    $self->is_authenticated(1)
      unless !defined($res->{Response}->{EnvironTag});
}



=method reconnect

Reconnects to API server in case of timeout

=cut

sub reconnect {
    my $self = shift;
    $self->close;
    $self->login;
    $self->request_id = 1;
}

=method environment_info

Return Juju Environment information

=cut

sub environment_info {
    my $self = shift;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {"Type" => "Client", "Request" => "EnvironmentInfo"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method environment_uuid

Environment UUID from client connection

=cut
sub environment_uuid {
    my $self = shift;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {"Type" => "Client", "Request" => "EnvironmentUUID"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


=method environment_unset ($items)

Environment UUID from client connection

=cut

sub environment_unset {
    my ($self, $items) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "EnvironmentUnset",
        "Params"  => $items
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method find_tools ($major_version, $minor_version, $series, $arch)

Returns list containing all tools matching specified parameters

C<major_verison> - major version int

C<minor_verison> - minor version int

C<series> - Distribution series (eg, trusty)

C<arch> - architecture

=cut
sub find_tools {
    my ($self, $major, $minor, $series, $arch) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "EnvironmentUnset",
        "Params"  => {
            MajorVersion => int($major),
            MinorVersion => int($minor),
            Arch         => $arch,
            Series       => $series
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


=method agent_version

Returns version of api server

=cut
sub agent_version {
    my $self = shift;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {"Type" => "Client", "Request" => "AgentVersion"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method abort_current_upgrade

Aborts and archives the current upgrade synchronization record, if any.

=cut
sub abort_current_upgrade {
    my $self = shift;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {"Type" => "Client", "Request" => "AbortCurrentUpgrade"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


=method status

Returns juju environment status

=cut

sub status {
    my $self   = shift;
    my $cb     = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"   => "Client",
        "Request" => "FullStatus"
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method client_api_host_ports

Returns network hostports for each api server

=cut
sub client_api_host_ports {
    my $self   = shift;
    my $cb     = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"   => "Client",
        "Request" => "APIHostPorts"
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


=method get_watcher

Returns watcher

=cut

sub get_watcher {
    my $self = shift;
    my $cb     = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {"Type" => "Client", "Request" => "WatchAll"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method get_watched_tasks ($watcher_id)

List of all watches for Id

=cut

sub get_watched_tasks {
    my ($self, $watcher_id) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    die "Unable to run synchronously, provide a callback" unless $cb;

    my $params =
      {"Type" => "AllWatcher", "Request" => "Next", "Id" => $watcher_id};

    # non-block
    return $self->call($params, $cb);
}


=method add_charm ($charm_url)

Add charm

C<charm_url> - url of charm

=cut

sub add_charm {
    my ($self, $charm_url) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "AddCharm",
        "Params"  => {"URL" => $charm_url}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method get_charm ($charm_url)

Get charm

C<charm_url> - url of charm

=cut

sub get_charm {
    my ($self, $charm_url) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "CharmInfo",
        "Params"  => {"CharmURL" => $charm_url}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method get_environment_constraints

Get environment constraints

=cut

sub get_environment_constraints {
    my $self   = shift;
    my $cb     = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "GetEnvironmentConstraints"
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);

}

=method set_environment_constraints ($constraints)

Set environment constraints

C<constraints> - environment constraints

=cut

sub set_environment_constraints {
    my ($self, $constraints) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "SetEnvironmentConstraints",
        "Params"  => $constraints
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method environment_get

Returns all environment settings

=cut

sub environment_get {
    my $self   = shift;
    my $cb     = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "EnvironmentGet"
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method environment_set ($config)

C<config> - Config parameters

=cut

sub environment_set {
    my ($self, $config) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "EnvironmentSet",
        "Params"  => {"Config" => $config}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method add_machine ($series, $constraints, $machine_spec, $parent_id, $container_type)

Allocate new machine from the iaas provider (i.e. MAAS)

C<series> - OS series (i.e precise)

C<constraints> - machine constraints

C<machine_spec> - specific machine

C<parent_id> - id of parent

C<container_type> - kvm or lxc container type

=cut

sub add_machine {
    my $self = shift;
    my $series = shift // "trusty";
    # Go ahead and pull this to strip off the argument list
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

    my ($constraints, $machine_spec, $parent_id, $container_type) = @_;
    my $params = {
        "Series"        => $series,
        "Jobs"          => [$self->Jobs->{HostUnits}],
        "ParentId"      => "",
        "ContainerType" => ""
    };

    # validate constraints
    if (defined($constraints) and is_hashref($constraints)) {
        $params->{Constraints} = $self->_prepare_constraints($constraints);
    }

    # if we're here then assume constraints is good and we can check the
    # rest of the arguments
    if (defined($machine_spec)) {
        die "Cant specify machine spec with container_type/parent_id"
          if $parent_id or $container_type;
        ($params->{ParentId}, $params->{ContainerType}) = split /:/,
          $machine_spec;
    }

    return $self->add_machines([$params]) unless $cb;
    return $self->add_machines([$params], $cb);
}

=method add_machines ($machines)

Add multiple machines from iaas provider

C<machines> - List of machines

=cut

sub add_machines {
    my ($self, $machines) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "AddMachines",
        "Params"  => {"MachineParams" => $machines}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


=method destroy_environment

Destroys Juju environment

=cut

sub destroy_environment {
    my $self   = shift;
    my $cb     = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "DestroyEnvironment"
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);

}

=method destroy_machines

Destroy machines

=cut

sub destroy_machines {
    my ($self, $machine_ids, $force) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

    my $params = {
        "Type"    => "Client",
        "Request" => "DestroyMachines",
        "Params"  => {"MachineNames" => $machine_ids}
    };

    if ($force) {
        $params->{Params}->{Force} = 1;
    }

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);

}

=method provisioning_script

Not implemented

=method add_relation ($endpoint_a, $endpoint_b)

Sets a relation between units

=cut

sub add_relation {
    my ($self, $endpoint_a, $endpoint_b) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        'Type'    => 'Client',
        'Request' => 'AddRelation',
        'Params'  => {'Endpoints' => [$endpoint_a, $endpoint_b]}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method remove_relation ($endpoint_a, $endpoint_b)

Removes relation between endpoints

=cut

sub remove_relation {
    my ($self, $endpoint_a, $endpoint_b) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        'Type'    => 'Client',
        'Request' => 'DestroyRelation',
        'Params'  => {'Endpoints' => [$endpoint_a, $endpoint_b]}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method deploy

Deploys a charm to service

B<Params>

C<charm> - charm to deploy

C<service_name> - name of service to set. can be same name as charm, however, recommended to pick something unique and identifiable.

C<num_units> - (optional) number of service units

C<config_yaml> - (optional) A YAML formatted string of charm options

C<constraints> - (optional) Machine hardware constraints

C<machine_spec> - (optional) Machine specification

More information on deploying can be found by running C<juju help deploy>.

=cut

sub deploy {
    my $self = shift;
    my ($charm, $service_name) =
      validate_pos({type => SCALAR}, {type => SCALAR});
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

    # parse additional arguments
    my ($num_units, $config_yaml, $constraints, $machine_spec) = @_;

    my $params = {
        Type    => "Client",
        Request => "ServiceDeploy",
        Params  => {ServiceName => $service_name}
    };
    my $_charm_url = $self->util->query_cs($charm);
    $params->{Params}->{CharmUrl} = $_charm_url->{charm}->{url};
    $num_units = 1 unless $num_units;
    $params->{Params}->{NumUnits} = $num_units;
    $params->{Params}->{ConfigYAML} =
      defined($config_yaml) ? $config_yaml : "";

    if (defined($constraints) and is_hashref($constraints)) {
        $params->{Params}->{Constraints} =
          $self->_prepare_constraints($constraints);
    }
    if ($machine_spec) {
        $params->{Params}->{ToMachineSpec} = "$machine_spec";
    }

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method service_set ($service_name, $config)

Set's configuration parameters for unit

C<service_name> - name of service (ie. blog)

C<config> - hash of config parameters

=cut

sub service_set {
    my ($self, $service_name, $config) = @_;
    my $cb     = ref $_[-1] eq 'CODE' ? pop : undef;

    die "Not a hash" unless ref $config eq 'HASH';
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceSet",
        "Params"  => {
            "ServiceName" => $service_name,
            "Options"     => $config
        }
    };
    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method service_unset ($service_name, $config_keys)

Unsets configuration value for service to restore charm defaults

C<service_name> - name of service

C<config_keys> - hash of config keys to unset

=cut

sub unset_config {
    my ($self, $service_name, $config_keys) = @_;
    my $cb     = ref $_[-1] eq 'CODE' ? pop : undef;

    my $params = 
        {   "Type"    => "Client",
            "Request" => "ServiceUnset",
            "Params"  => {
                "ServiceName" => $service_name,
                "Options"     => $config_keys
            }
        };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method service_set_charm ($service_name, $charm_url, $force)

Sets charm url for service

C<service_name> - name of service

C<charm_url> - charm location (ie. cs:precise/wordpress)

=cut

sub set_charm {
    my ($self, $service_name, $charm_url, $force) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

    $force = 0 unless $force;
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceSetCharm",
        "Params"  => {
            "ServiceName" => $service_name,
            "CharmUrl"    => $charm_url,
            "Force"       => $force
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method service_get ($service_name)

Returns information on charm, config, constraints, service keys.

C<service_name> - name of service

=cut

sub service_get {
    my ($self, $service_name) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceGet",
        "Params"  => {"ServiceName" => $service_name}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method get_config ($service_name)

Get service configuration

C<service_name> - name of service

=cut

sub get_config {
    my ($self, $service_name) = @_;
    my $cb     = ref $_[-1] eq 'CODE' ? pop : undef;

    my $svc = $self->service_get($service_name);
    return $svc->{Config} unless $cb;
    return $cb->($svc->{Config});
}

=method get_service_constraints ($service_name)

Returns the constraints for the given service.

C<service_name> - Name of service

=cut

sub get_service_constraints {
    my ($self, $service_name) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "GetServiceConstraints",
        "Params"  => {"ServiceName" => $service_name}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method set_service_constraints ($service_name, $constraints)

C<service_name> - Name of service

C<constraints> - Service constraints

=cut

sub set_service_constraints {
    my ($self, $service_name, $constraints) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "SetServiceConstraints",
        "Params"  => {
            "ServiceName" => $service_name,
            "Constraints" => $self->_prepare_constraints($constraints)
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method share_environment($users)

Allows the given users access to the environment.

=cut
sub share_environment {
    my ($self, $users) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "ShareEnvironment",
        "Params"  => $users
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method unshare_environment($users)

Removes the given users access to the environment.

=cut
sub unshare_environment {
    my ($self, $users) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "UnshareEnvironment",
        "Params"  => $users
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


=method service_destroy ($service_name)

Destroys a service

C<service_name> - name of service

=cut

sub service_destroy {
    my ($self, $service_name) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceDestroy",
        "Params"  => {"ServiceName" => $service_name}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method service_expose ($service_name)

Expose service

C<service_name> - Name of service

=cut

sub service_expose {
    my ($self, $service_name) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceExpose",
        "Params"  => {"ServiceName" => $service_name}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


=method service_unexpose ($service_name)

Unexpose service

C<service_name> - Name of service

=cut

sub service_unexpose {
    my ($self, $service_name) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceUnexpose",
        "Params"  => {"ServiceName" => $service_name}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method service_charm_relations

All possible relation names of a service

=cut

sub service_charm_relations {
    my ($self, $service_name) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceCharmRelations",
        "Params"  => {"ServiceName" => $service_name}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method add_service_units ($service_name, $num_units)

Adds given number of units to a service

=cut

sub add_service_units {
    my ($self, $service_name, $num_units) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

    $num_units = 1 unless $num_units;
    my $params = {
        "Type"    => "Client",
        "Request" => "AddServiceUnits",
        "Params"  => {
            "ServiceName" => $service_name,
            "NumUnits"    => $num_units
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method add_service_unit ($service_name, $machine_spec)

Add unit to specific machine

=cut

sub add_service_unit {
    my ($self, $service_name, $machine_spec) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

    $machine_spec = 0 unless $machine_spec;
    my $params = {
        "Type"    => "Client",
        "Request" => "AddServiceUnits",
        "Params"  => {
            "ServiceName" => $service_name,
            "NumUnits"    => 1
        }
    };

    if ($machine_spec) {
        $params->{Params}->{ToMachineSpec} = $machine_spec;
    }

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method destroy_service_units ($unit_names)

Decreases number of units dedicated to a service

=cut

sub destroy_service_units {
    my ($self, $unit_names) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "DestroyServiceUnits",
        "Params"  => {"UnitNames" => $unit_names}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method resolved ($unit_name, $retry)

Clear errors on unit

C<unit_name> - id of unit (eg, mysql/0)

C<retry> - bool

=cut

sub resolved {
    my ($self, $unit_name, $retry) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

    $retry = 0 unless $retry;
    my $params = {
        "Type"    => "Client",
        "Request" => "Resolved",
        "Params"  => {
            "UnitName" => $unit_name,
            "Retry"    => $retry
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method run

Not implemented yet.

=cut


=method set_annotations

Set annotations on entity, valid types are C<service>, C<unit>,
C<machine>, C<environment>

=cut

sub set_annotations {
    my ($self, $entity, $entity_type, $annotation) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "SetAnnotations",
        "Params"  => {
            "Tag"   => sprintf("%s-%s", $entity_type, $entity =~ s|/|-|g),
            "Pairs" => $annotation
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method get_annotations ($entity, $entity_type)

Returns annotations that have been set on the given entity.

=cut

sub get_annotations {
    my ($self, $entity, $entity_type) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "GetAnnotations",
        "Params"  => {
            "Tag" => "Tag" =>
              sprintf("%s-%s", $entity_type, $entity =~ s|/|-|g)
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method private_address($target)

Get private address of machine or unit

  $self->private_address('1');  # get address of machine 1
  $self->private_address('mysql/0');  # get address of first unit of mysql

=cut
sub private_address {
    my ($self, $target) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "PrivateAddress",
        "Params"  => {"Target" => $target}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method public_address($target)

Returns the public address of the specified machine or unit. For a
machine, target is an id not a tag.

  $self->public_address('1');  # get address of machine 1
  $self->public_address('mysql/0');  # get address of first unit of mysql

=cut
sub public_address {
    my ($self, $target) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "PublicAddress",
        "Params"  => {"Target" => $target}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method service_set_yaml ($service, $yaml)

Sets configuration options on a service given options in YAML format.

=cut
sub service_set_yaml {
    my ($self, $service, $yaml) = @_;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = {
        "Type"    => "Client",
        "Request" => "PublicAddress",
        "Params"  => {
            "ServiceName" => $service,
            "Config"      => Dump($yaml)
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


1;
