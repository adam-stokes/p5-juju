package Juju;
# ABSTRACT: Perl bindings for http://juju.ubuntu.com/

use strict;
use warnings;

use Moose;
use Moose::Autobox;

has conn => (
    is   => 'ro',
    isa  => 'Juju::RPC',
    lazy => 1
);

1;

=head1 DESCRIPTION

Perl bindings for Juju. See L<Juju::Manual> for more information.

=cut
