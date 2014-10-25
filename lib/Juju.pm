package Juju;

# ABSTRACT: Perl bindings for Juju

=head1 DESCRIPTION

Perl non-blocking/blocking bindings for Juju. See
L<Juju::Manual::Quickstart> for more information.

=head1 SEE ALSO
https://juju.ubuntu.com

=cut

use Moose;
use namespace::autoclean;
extends 'Juju::Environment';

1;
