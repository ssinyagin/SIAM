package SIAM::Device;

use warnings;
use strict;

use base 'SIAM::Object';


=head1 NAME

SIAM::Device - device object class

=head1 SYNOPSIS


=head1 METHODS

=head2 get_all_service_units

returns arrayref with all C<SIAM::ServiceUnit> objects associated with
this device.

=cut

sub get_all_service_units
{
    my $self = shift;
    
    return $self->get_objects_by_attribute
        ('SIAM::ServiceUnit', 'siam.svcunit.device_id', $self->id);
}


# mandatory attributes

my $mandatory_attributes =
    [ 'siam.device.inventory_id',
      'siam.device.name'];

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
