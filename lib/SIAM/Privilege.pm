package SIAM::Privilege;

use warnings;
use strict;

use base 'SIAM::Object';

use SIAM::AccessScope;


=head1 NAME

SIAM::Privilege - Privilege object class

=head1 SYNOPSIS


=head1 METHODS

=head2 match_object

Expects an object as an argument. Returns true if the object matches the
related scope.

=cut


sub match_object
{
    my $self = shift;
    my $obj = shift;

    my $scopeid = $self->attr('privilege.access_scope_id');
    my $scope = new SIAM::AccessScope($self->_driver, $scopeid);    
    return $scope->match_object($obj);
}



=head2 matches_all

Returns true if the privilege is associated with a match-all scope.

=cut


sub matches_all
{
    my $self = shift;
    return SIAM::AccessScope->matches_all
        ($self->attr('privilege.access_scope_id'));
}


# mandatory attributes

my $mandatory_attributes =
    [ 'privilege.access_scope_id',
      'privilege.type' ];

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
