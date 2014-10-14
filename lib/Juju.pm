package Juju;

# ABSTRACT: Perl bindings for Juju

=head1 DESCRIPTION

Perl non-blocking/blocking bindings for Juju. See
L<Juju::Manual::Quickstart> for more information.

=head1 SEE ALSO
https://juju.ubuntu.com

=cut

use strict;
use warnings;
use Moo;
use namespace::clean;
extends 'Juju::Environment';

1;
