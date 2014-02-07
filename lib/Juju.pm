package Juju;
# ABSTRACT: Juju library for perl

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

=head1 SYNOPSIS

    use Juju;
    my $juju = Juju->new(user => 'user-admin' password => 'fds9fdsa8f');

=cut
