package SIAM::ServiceComponent;

use warnings;
use strict;

use base 'SIAM::Object';

use SIAM::Device;

=head1 NAME

SIAM::ServiceComponent - Service Component object class

=head1 SYNOPSIS

=head1 METHODS

=head2 get_device

    $device = $unit->get_device();

The method returns a SIAM::Device object instantiated from
C<siam.svcc.device_id> parameter.

=cut

sub get_device
{
    my $self = shift;
    
    return $self->instantiate_object
        ('SIAM::Device', $self->attr('siam.svcc.device_id'));
}
            
    
# mandatory attributes

my $mandatory_attributes =
    [ 'siam.svcc.name',
      'siam.svcc.type',
      'siam.svcc.inventory_id',
      'siam.svcc.device_id' ];

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
