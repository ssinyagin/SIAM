package SIAM::ServiceUnit;

use warnings;
use strict;

use base 'SIAM::Object';

use SIAM::ServiceDataElement;
use SIAM::Device;

=head1 NAME

SIAM::ServiceUnit - Service Unit object class

=head1 SYNOPSIS

   my $dataelements = $service->get_data_elements();

=head1 METHODS

=head2 get_data_elements

Returns arrayref with SIAM::ServiceDataElement objects

=cut

sub get_data_elements
{
    my $self = shift;
    return $self->get_contained_objects('SIAM::ServiceDataElement');
}


# mandatory attributes

my $mandatory_attributes =
    [ 'siam.svcunit.name',
      'siam.svcunit.type',
      'siam.svcunit.inventory_id',
      'siam.svcunit.device_id' ];

sub _mandatory_attributes
{
    return $mandatory_attributes;
}


sub _manifest_attributes
{
    my $ret = [];
    push(@{$ret}, @{$mandatory_attributes},
         @{ SIAM::ServiceDataElement->_manifest_attributes() });

    return $ret;

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
