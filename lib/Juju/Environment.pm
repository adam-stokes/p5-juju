package Juju::Environment;

# ABSTRACT: Exposed juju api environment

=head1 SYNOPSIS

  use Juju;

  my $juju =
    Juju->new(endpoint => 'wss://localhost:17070', password => 's3cr3t');

=cut

use strict;
use warnings;
use JSON::PP;
use YAML::Tiny qw(Dump);
use Data::Validate::Type qw(:boolean_tests);
use Function::Parameters qw(:strict);
use Juju::Util;
use Moo;
use namespace::clean;
with 'Juju::RPC';

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

=attr util

L<Juju::Util> wrapper

=cut

has password => (is => 'ro', required => 1);
has is_authenticated => (is => 'rw', lazy => 1);
has endpoint => (is => 'ro', default => sub {'wss://localhost:17070'});
has username => (is => 'ro', default => sub {'user-admin'});
has Jobs => (
    is      => 'ro',
    default => sub {
        {   HostUnits     => 'JobHostUnits',
            ManageEnviron => 'JobManageEnviron',
            ManageState   => 'JobManageSate'
        };
    }
);
has util => (is => 'ro', default => sub { Juju::Util->new });


=method _prepare_constraints

Makes sure cpu-cores, cpu-power, mem are integers

B<Params>

=for :list
* C<constraints>
hash of service constraints

=cut

method _prepare_constraints ($constraints) {
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

method login {
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

Reconnects to API server in case of timeout, this also resets the RequestId.

=cut

method reconnect {
    $self->close;
    $self->login;
    $self->request_id = 1;
}

=method environment_info

Return Juju Environment information

=cut

method environment_info($cb = undef) {
    my $params = {"Type" => "Client", "Request" => "EnvironmentInfo"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method environment_uuid

Environment UUID from client connection

=cut

method environment_uuid ($cb = undef) {
    my $params = {"Type" => "Client", "Request" => "EnvironmentUUID"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


=method environment_unset

Unset Environment settings

B<Params>

=for :list
* C<items>

=cut

method environment_unset ($items, $cb = undef) {
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

=method find_tools

Returns list containing all tools matching specified parameters

B<Params>

=for :list
* C<major_verison>
major version int
* C<minor_verison>
minor version int
* C<series>
Distribution series (eg, trusty)
* C<arch>
architecture

=cut

method find_tools ($major, $minor, $series, $arch, $cb = undef) {
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

method agent_version ($cb = undef) {
    my $params = {"Type" => "Client", "Request" => "AgentVersion"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method abort_current_upgrade

Aborts and archives the current upgrade synchronization record, if any.

=cut

method abort_current_upgrade ($cb = undef) {
    my $params = {"Type" => "Client", "Request" => "AbortCurrentUpgrade"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


=method status

Returns juju environment status

=cut

method status ($cb = undef) {
    my $params = {
        "Type"    => "Client",
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

method client_api_host_ports ($cb = undef) {
    my $params = {
        "Type"    => "Client",
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

method get_watcher ($cb = undef) {
    my $params = {"Type" => "Client", "Request" => "WatchAll"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method get_watched_tasks

List of all watches for Id

B<Params>

=for :list
C<watcher_id>

=cut

method get_watched_tasks ($watcher_id, $cb = undef) {
    die "Unable to run synchronously, provide a callback" unless $cb;

    my $params =
      {"Type" => "AllWatcher", "Request" => "Next", "Id" => $watcher_id};

    # non-block
    return $self->call($params, $cb);
}


=method add_charm

Add charm

B<Params>

=for :list
* C<charm_url>
url of charm

=cut

method add_charm ($charm_url, $cb = undef) {
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

=method get_charm

Get charm

B<Params>

=for :list
* C<charm_url>
url of charm

=cut

method get_charm ($charm_url, $cb = undef) {
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

method get_environment_constraints ($cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "GetEnvironmentConstraints"
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);

}

=method set_environment_constraints

Set environment constraints

B<Params>

=for :list
* C<constraints>
environment constraints

=cut

method set_environment_constraints (ArrayRef $constraints, $cb = undef) {
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

method environment_get ($cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "EnvironmentGet"
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method environment_set

Sets the given key-value pairs in the environment.

B<Params>

=for :list
* C<config>
Config parameters

=cut

method environment_set ($config, $cb = undef) {
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

=method add_machine

Allocate new machine from the iaas provider (i.e. MAAS)

B<Params>

=for :list
* C<series>
OS series (i.e precise)
* C<constraints>
machine constraints
* C<machine_spec>
specific machine
* C<parent_id>
id of parent
* C<container_type>
kvm or lxc container type

=cut

method add_machine ($series, $constraints = undef, $machine_spec = undef, $parent_id = undef, $container_type = undef, $cb = undef) {
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

=method add_machines

Add multiple machines from iaas provider

B<Params>

=for :list
* C<machines>
List of machines

=cut

method add_machines ($machines, $cb = undef) {
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

method destroy_environment ($cb = undef) {
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

B<Params>

=for :list
* C<machine_ids>
List of machines
* C<force>
Force destroy

=cut

method destroy_machines ($machine_ids, $force = 0, $cb = undef) {
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

=method add_relation

Sets a relation between units

B<Params>

=for :list
* C<endpoint_a>
First unit endpoint
* C<endpoint_b>
Second unit endpoint

=cut

method add_relation ($endpoint_a, $endpoint_b, $cb = undef) {
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

=method destroy_relation

Removes relation between endpoints

B<Params>

=for :list
* C<endpoint_a>
First unit endpoint
* C<endpoint_b>
Second unit endpoint

=cut

method destroy_relation ($endpoint_a, $endpoint_b, $cb = undef) {
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

    $juju->deploy(
        'mysql',
        'mysql',
        1,
        undef,
        undef,
        undef,
        sub {
            my $val = shift;
            print Dumper($val) if defined($val->{Error});
        }
    );

B<Params>

=for :list
* C<charm>
charm to deploy, can be in the format of B<series/charm> if needing to specify a different series
* C<service_name>
name of service to set. same name as charm
* C<num_units>
(optional) number of service units
* C<config_yaml>
(optional) A YAML formatted string of charm options
* C<constraints>
(optional) Machine hardware constraints
* C<machine_spec>
(optional) Machine specification

More information on deploying can be found by running C<juju help deploy>.

=cut

method deploy ($charm, $service_name, $num_units = 1, $config_yaml = "", $constraints = "", $machine_spec = "", $cb = undef) {
    my $params = {
        Type    => "Client",
        Request => "ServiceDeploy",
        Params  => {ServiceName => $service_name}
    };

    # Check for series format
    my (@charm_args) = $charm =~ /(\w+)\/(\w+)/i;
    my $_charm_url = undef;
    if (scalar @charm_args == 2) {
        $_charm_url = $self->util->query_cs($charm_args[1], $charm_args[0]);
    }
    else {
        $_charm_url = $self->util->query_cs($charm);
    }

    $params->{Params}->{CharmUrl}   = $_charm_url->{charm}->{url};
    $params->{Params}->{NumUnits}   = $num_units;
    $params->{Params}->{ConfigYAML} = $config_yaml;
    $params->{Params}->{Constraints} =
      $self->_prepare_constraints($constraints);
    $params->{Params}->{ToMachineSpec} = "$machine_spec";

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method service_set

Set's configuration parameters for unit

B<Params>

=for :list
* C<service_name>
name of service (ie. blog)
* C<config>
hash of config parameters

=cut

method service_set ($service_name, $config = undef, $cb = undef) {
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

=method service_unset

Unsets configuration value for service to restore charm defaults

B<Params>

=for :list
* C<service_name>
name of service
* C<config_keys>
config items to unset

=cut

method unset_config ($service_name, $config_keys, $cb = undef) {
    my $params = {
        "Type"    => "Client",
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

=method service_set_charm

Sets charm url for service

B<Params>

=for :list
* C<service_name>
name of service
* C<charm_url> 
charm location (ie. cs:precise/wordpress)
* C<force>
(optional) for setting charm url, overrides any existing charm url already set.

=cut

method set_charm ($service_name, $charm_url, $force = 0, $cb = undef) {
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

=method service_get

Returns information on charm, config, constraints, service keys.

B<Params>

=for :list
* C<service_name> - name of service

=cut

method service_get ($service_name, $cb = undef) {
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

=method get_config

Get service configuration

B<Params>

=for :list
* C<service_name>
name of service

=cut

method get_config ($service_name, $cb = undef) {
    my $svc = $self->service_get($service_name);
    return $svc->{Config} unless $cb;
    return $cb->($svc->{Config});
}

=method get_service_constraints

Returns the constraints for the given service.

B<Params>

=for :list
* C<service_name>
Name of service

=cut

method get_service_constraints ($service_name, $cb = undef) {
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

=method set_service_constraints

Specifies the constraints for the given service.

B<Params>

=for :list
* C<service_name>
Name of service
* C<constraints>
Service constraints

=cut

method set_service_constraints ($service_name, $constraints, $cb = undef) {
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

=method share_environment

Allows the given users access to the environment.

B<Params>

=for :list
* C<users>
List of users to allow access

=cut

method share_environment ($users, $cb = undef) {
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

=method unshare_environment

Removes the given users access to the environment.

B<Params>

=for :list
* C<users>
List of users to remove access


=cut

method unshare_environment ($users, $cb = undef) {
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


=method service_destroy

Destroys a service

B<Params>

=for :list
* C<service_name>
name of service

=cut

method service_destroy ($service_name, $cb = undef) {
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

=method service_expose

Expose service

B<Params>

=for :list
* C<service_name>
Name of service

=cut

method service_expose ($service_name, $cb = undef) {
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


=method service_unexpose

Unexpose service

B<Params>

=for :list
* C<service_name>
Name of service

=cut

method service_unexpose ($service_name, $cb = undef) {
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

B<Params>

=for :list
* C<service_name>
Name of service

=cut

method service_charm_relations ($service_name, $cb = undef) {
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

=method add_service_units

Adds given number of units to a service

B<Params>

=for :list
* C<service_name>
Name of service
* C<num_units>
Number of units to add

=cut

method add_service_units ($service_name, $num_units = 1, $cb = undef) {
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

=method add_service_unit

Add unit to specific machine

B<Params>

=for :list
* C<service_name>
Name of service
* C<machine_spec>
Machine to add unit to

=cut

method add_service_unit ($service_name, $machine_spec = "", $cb = undef) {
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

=method destroy_service_units

Decreases number of units dedicated to a service

B<Params>

=for :list
* C<unit_names>
List of units to destroy

=cut

method destroy_service_units ($unit_names, $cb = undef) {
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

=method resolved

Clear errors on unit

B<Params>

=for :list
* C<unit_name>
id of unit (eg, mysql/0)
* C<retry>
Boolean to force a retry

=cut

method resolved ($unit_name, $retry = 0, $cb = undef) {
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

Run the Commands specified on the machines identified through the ids
provided in the machines, services and units slices.

Required parameters B<Commands>, B<Timeout>, and at B<least one>
C<Machine>, C<Service>, or C<Unit>.

    {
       command => "",
       timeout => TIMEDURATION
       machines => [MACHINE_IDS],
       services => [SERVICES_IDS],
       units => [UNITS_ID]
    }

Requires named parameters

B<Params>

=for :list
* C<command>
command to run
* C<timeout>
timeout
* C<machines>
(optional) List of machine ids
* C<services>
(optional) List of services ids
* C<units>
(optional) List of unit ids
* C<cb>
(optional) callback

=cut

method run ($command, $timeout, $machines = undef, $services = undef, $units = undef, $cb = undef) {
    my $params = {
        Type    => "Client",
        Request => "Run",
        Params  => {
            Commands => $command,
            Timeout  => $timeout,
            Machines => $machines,
            Services => $services,
            Units    => $units
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method run_on_all_machines

Runs the command on all the machines with the specified timeout.

B<Params>

=for :list
* C<command>
command to run
* C<timeout>
timeout

=cut

method run_on_all_machines ($command, $timeout, $cb = undef) {
    my $params = {
        Type    => "Client",
        Request => "RunOnAllMachines",
        Params  => {
            Commands => $command,
            Timeout  => int($timeout)
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

=method set_annotations

Set annotations on entity, valid types are C<service>, C<unit>,
C<machine>, C<environment>

B<Params>

=for :list
* C<entity>
* C<entity_type>
* C<annotation>

=cut

method set_annotations ($entity, $entity_type, $annotation, $cb = undef) {
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

=method get_annotations

Returns annotations that have been set on the given entity.

B<Params>

=for :list
* C<entity>
* C<entity_type>

=cut

method get_annotations ($entity, $entity_type, $cb = undef) {
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

=method private_address

Get private address of machine or unit

  $self->private_address('1');  # get address of machine 1
  $self->private_address('mysql/0');  # get address of first unit of mysql

B<Params>

=for :list
* C<target>
Target machine

=cut

method private_address ($target, $cb = undef) {
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

=method public_address

Returns the public address of the specified machine or unit. For a
machine, target is an id not a tag.

  $self->public_address('1');  # get address of machine 1
  $self->public_address('mysql/0');  # get address of first unit of mysql

B<Params>

=for :list
* C<target>
Target machine

=cut

method public_address ($target, $cb = undef) {
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

=method service_set_yaml

Sets configuration options on a service given options in YAML format.

B<Params>

=for :list
* C<service>
Service Name
* C<yaml>
YAML formatted string of options

=cut

method service_set_yaml ($service, $yaml, $cb = undef) {
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
