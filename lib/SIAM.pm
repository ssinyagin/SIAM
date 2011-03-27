package SIAM;

use warnings;
use strict;

use base 'SIAM::Object';

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
    
    my $self = $class->SUPER::new( $driver, {'object.id' => 'ROOT'} );
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
# cperl-brace-offset: -4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: 0
# End:
