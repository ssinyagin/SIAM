package SIAM::Contract;

use warnings;
use strict;

use base 'SIAM::Object';


=head1 NAME

SIAM::Contract - Contract object class

=head1 SYNOPSIS

   my $all_contracts = $siam->get_all_contracts();
   my $user_contracts =
       $siam->get_contracts_by_user_privilege($user, 'ViewContract');


=head1 METHODS


=cut


# mandatory attributes

my $mandatory_attributes =
    [ 'contract.inventory_id',
      'contract.customer_name',
      'object.access_scope_id',
      'contract.last_modified' ];

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
