package Juju::Error;

# ABSTRACT: error exception handler

=head1 SYNOPSIS

  use Juju::Error::Environment;
  Juju::Error::Environment->throw(
    error_message => 'Unable to query api',
    method_name => 'deploy'
  );

=cut

use Moose;
extends 'Throwable::Error';
use namespace::autoclean;

has status_code => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    default  => 127,
    documentation =>
      'Juju does not provide reliable return codes, keep the default until otherwise noted.'
);

has error_message => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    documentation => 'An error response string'
);

has method_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);


__PACKAGE__->meta->make_immutable;
1;
