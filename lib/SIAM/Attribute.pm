package SIAM::Attribute;

use warnings;
use strict;

use base 'SIAM::Object';


=head1 NAME

SIAM::Attribute - Attribute object class

=head1 SYNOPSIS

=head1 METHODS

=head2 name

Returns the value of C<attribute.name> attribute.

=cut

sub name
{
    my $self = shift;
    return $self->attr('attribute.name');
}


# mandatory attributes

my $mandatory_attributes =
    [ 'attribute.name' ];

sub _mandatory_attributes
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
