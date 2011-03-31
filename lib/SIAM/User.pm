package SIAM::User;

use warnings;
use strict;

use base 'SIAM::Object';

use SIAM::Privilege;
use SIAM::AccessScope;

=head1 NAME

SIAM::User - User object class

=head1 SYNOPSIS

   my $user = $siam->get_user($uid);


=head1 METHODS

=head2 has_privilege

  $user->has_privilege('ViewContract', $contract)

Expects a privilege string and an object. Returns true if the object matches
the privilege

=cut

sub has_privilege
{
    my $self = shift;
    my $priv = shift;
    my $obj = shift;

    my $privileges = $self->get_contained_objects
        ('SIAM::Privilege',
         {'match_attribute' => ['privilege.type', [$priv]]});

    foreach my $privilege (@{$privileges})
    {
        if( $privilege->match_object($obj) )
        {
            return 1;
        }        
    }

    return undef;
}



# mandatory attributes

my $mandatory_attributes =
    [ 'user.uid' ];

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
