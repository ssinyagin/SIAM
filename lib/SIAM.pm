package SIAM;

use warnings;
use strict;

use base 'SIAM::Object';

use SIAM::Contract;
use SIAM::User;
use SIAM::Privilege;
use SIAM::Attribute;

=head1 NAME

SIAM - Service Inventory Abstraction Model

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

    use SIAM;

    my $siam = new SIAM({configuration...}, {options...});


=head1 METHODS

=head2 new

Expects two hash refs: configuration and options.

=head3 Configuration

=over 4

=item * Driver

A hash with two entries: C<Class> identifying the driver module class
which is going to be C<require>'d; and C<Options>, a hash which is
supplied to the driver's C<new> method.

=back


=cut

sub new
{
    my $class = shift;
    my $config = shift;
    my $options = shift;

    my $drvclass = $config->{'Driver'}{'Class'};
    my $drvopts = $config->{'Driver'}{'Options'};

    eval('require ' . $drvclass);
    if( $@ )
    {
        SIAM::Object->critical($@);
        return undef;
    }
    
    my $driver = eval($drvclass . '->new($drvopts)');
    if( $@ )
    {
        SIAM::Object->critical($@);
        return undef;
    }
    
    if( not defined($driver) )
    {
        SIAM::Object->critical('Failed to initialize the driver');
        return undef;
    }
    
    my $self = $class->SUPER::new( $driver, 'SIAM.ROOT' );
    return undef unless defined($self);
    
    return $self;
}


=head2 connect

Connects the driver to its databases. Returns false in case of problems.

=cut

sub connect
{
    my $self = shift;
    if( not $self->_driver->connect() )
    {
        $self->error($self->_driver->errmsg);
        return undef;
    }

    return 1;
}


=head2 disconnect

Disconnects the driver from its underlying databases.

=cut

sub disconnect
{
    my $self = shift;
    $self->_driver->disconnect();
}


=head2 get_user

Expects a UID string as an argument. Returns a C<SIAM::User> object or undef.

=cut

sub get_user
{
    my $self = shift;
    my $uid = shift;

    my $users = $self->get_contained_objects
        ('SIAM::User', {'match_attribute' => ['user.uid', [$uid]]});
    if( scalar(@{$users}) > 1 )
    {
        $self->error('Driver returned more than one SIAM::User object with ' .
                     'user.uid=' . $uid);
    }
    return $users->[0];
}


=head2 get_all_contracts

Returns an arrayref with all available C<SIAM::Contract> objects.

=cut

sub get_all_contracts
{
    my $self = shift;
    return $self->get_contained_objects('SIAM::Contract');
}



=head2 get_contracts_by_user_privilege

  my $user_contracts =
      $siam->get_contracts_by_user_privilege($user, 'ViewContract');

Arguments: C<SIAM::User> object and a privilege string.  Returns
arrayref with all available C<SIAM::Contract> objects that match the
privilege.

=cut

sub get_contracts_by_user_privilege
{
    my $self = shift;
    my $user = shift;
    my $priv = shift;

    my $privileges = $user->get_contained_objects
        ('SIAM::Privilege',
         {'match_attribute' => ['privilege.type', [$priv]]});
    
    my %scope_ids;

    foreach my $privilege (@{$privileges})
    {
        if( $privilege->matches_all() )
        {
            return $self->get_contained_objects('SIAM::Contract');
        }
        
        $scope_ids{$privilege->attr('privilege.access_scope_id')} = 1;
    }

    return $self->get_contained_objects
        ('SIAM::Contract',
         {'match_attribute' => ['object.access_scope_id', [keys %scope_ids]]});
}
         


=head2 filter_visible_attributes

   my $visible_attrs =
       $siam->filter_visible_attributes($user, $object_attrs);

Arguments: C<SIAM::User> object and a hashref with object attributes.
Returns a new hashref with copies of attributes which are allowed to be
shown to the user as specified by C<ViewAttribute> privileges.

=cut

sub filter_visible_attributes
{
    my $self = shift;
    my $user = shift;
    my $attrs_in = shift;

    my $attrs_out = {};

    # Fetch SIAM::Attribute objects only once and cache them by attribute.name
    if( not defined($self->{'siam_attribute_objects'}) )
    {
        $self->{'siam_attribute_objects'} = {};
        foreach my $obj (@{ $self->get_contained_objects('SIAM::Attribute') })
        {
            my $name = $obj->attr('attribute.name');
            $self->{'siam_attribute_objects'}{$name} = $obj;
        }
    }

    my $privileges = $user->get_contained_objects
        ('SIAM::Privilege',
         {'match_attribute' => ['privilege.type', ['ViewAttribute']]});
    
    foreach my $privilege (@{$privileges})
    {
        if( $privilege->matches_all() )
        {
            # this user can see all. Copy everything and return.
            while( my($key, $val) = each %{$attrs_in} )
            {
                $attrs_out->{$key} = $val;
            }

            return $attrs_out;
        }
        else
        {
            while( my($key, $val) = each %{$attrs_in} )
            {
                my $attr_obj = $self->{'siam_attribute_objects'}{$key};
                if( defined($attr_obj) and
                    $privilege->match_object($attr_obj) )
                {
                    $attrs_out->{$key} = $val;
                }
            }
        }
    }

    return $attrs_out;
}

    



=head1 AUTHOR

Stanislav Sinyagin, C<< <ssinyagin at k-open.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-siam at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SIAM>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SIAM


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SIAM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SIAM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SIAM>

=item * Search CPAN

L<http://search.cpan.org/dist/SIAM/>

=back



=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stanislav Sinyagin.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

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
