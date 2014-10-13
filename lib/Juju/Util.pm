package Juju::Util;

# ABSTRACT: helper methods for Juju

=head1 SYNOPSIS

  use Juju::Util;
  my $util = Juju::Util->new;
  my $charm = $util->query_cs('wordpress', 'precise');

=cut

use strict;
use warnings;
use HTTP::Tiny;
use JSON::PP;
use Params::Validate qw(:all);
use Class::Tiny {series => qr/precise|trusty|utopic/};

=method query_cs

helper for querying charm store for charm details

B<Params>

=for :list
* C<charm>
name of charm to query
* C<series>
(optional) series to limit to (defaults: trusty)

=cut

sub query_cs {
    my $self = shift;
    my ($charm, $series) = validate_pos(
        @_, 1,
        {   optional => 1,
            default  => 'trusty',
            type     => SCALAR,
            regex    => $self->series
        }
    );
    my $cs_url = 'https://manage.jujucharms.com/api/3/charm';

    my $composed_url = sprintf("%s/%s/%s", $cs_url, $series, $charm);
    my $res = HTTP::Tiny->new->get($composed_url);
    die "Unable to query charm store: ".$res->{reason} unless $res->{success};
    return decode_json($res->{content});
}

1;
