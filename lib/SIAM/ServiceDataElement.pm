package SIAM::ServiceDataElement;

use warnings;
use strict;

use base 'SIAM::Object';


=head1 NAME

SIAM::ServiceDataElement - Service data element object class

=head1 SYNOPSIS


=head1 METHODS

=cut


# mandatory attributes

my $mandatory_attributes =
    [ 'siam.svcdata.name',
      'siam.svcdata.type',
      'siam.svcdata.driver_class' ];

sub _mandatory_attributes
{
    return $mandatory_attributes;
}

sub _manifest_attributes
{
    return $mandatory_attributes;
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:
