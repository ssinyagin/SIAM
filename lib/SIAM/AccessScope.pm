package SIAM::AccessScope;

use warnings;
use strict;

use base 'SIAM::Object';


=head1 NAME

SIAM::AccessScope - access scope object class

=head1 SYNOPSIS


=head1 INSTANCE METHODS

=head2 new

  $scope = new SIAM::AccessScope($driver, {'object.id' => $id})

Instantiates a new object. The following object IDs are predefined and
are not fetched from the driver:

=over 4

=item * SIAM.SCOPE.ALL.CONTRACTS

The access scope with the name I<AllContracts>. All contract objects are
implicitly included in it.

=item * SIAM.SCOPE.ALL.ATTRIBUTES

The access scope with the name I<AllAttributes>. All attribute names are
implicitly in it.

=back

=cut

my %match_all_id =
    ('SIAM.SCOPE.ALL.CONTRACTS' =>
     {
      'scope.name' => 'AllContracts',
      'scope.applies_to' => 'SIAM::Contract',
     },
     
     'SIAM.SCOPE.ALL.ATTRIBUTES' =>
     {
      'scope.name' => 'AllAttributes',
      'scope.applies_to' => 'SIAM::Attribute',
     },
    );


sub new
{
    my $class = shift;
    my $driver = shift;
    my $attributes = shift;

    my $id = $attributes->{'object.id'};
    
    if( defined($id) and defined($match_all_id{$id}) )
    {
        my $self = {};
        bless $self, $class;

        $self->{'_attr'} = {'object.id' => $id};
        while( my($key, $val) = each %{$match_all_id{$id}} )
        {
            $self->{'_attr'}{$key} = $val;
        }

        return $self;
    }
    else
    {
        return $class->SUPER::new( $driver, $attributes );
    }
}



=head2 match_object

Expects an object as an argument. Returns true if the object matches the scope.

=cut


sub match_object
{
    my $self = shift;
    my $obj = shift;

    # scope.applies_to should match the object class
    if( $obj->attr('object.class') ne $self->attr('scope.applies_to') )
    {
        return undef;
    }

    # check if we are one of the predefined scopes
    if( defined($match_all_id{$self->id}) )
    {
        return 1;
    }

    # check if object.access_scope_id matches our ID
    if( $obj->attr('object.access_scope_id') eq $self->id )
    {
        return 1;
    }

    return undef;
}



=head1 CLASS METHODS


=head2 matches_all

Takes an ID of an SIAM::AccessScope object and returns true if it's a
match-all scope.

=cut


sub matches_all
{
    my $class = shift;
    my $id = shift;

    return defined($match_all_id{$id});
}



# mandatory attributes

my $mandatory_attributes =
    [ 'scope.name',
      'scope.applies_to' ];

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
