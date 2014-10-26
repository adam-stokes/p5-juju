package Juju::Error::RPC;

# ABSTRACT: RPC error exception class

use Moose;
extends 'Juju::Error';


__PACKAGE__->meta->make_immutable;
1;
