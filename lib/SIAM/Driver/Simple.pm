package SIAM::Driver::Simple;

use warnings;
use strict;

use YAML ();
use Log::Handler;

=head1 NAME


SIAM::Driver::Simple - a reference implementation of SIAM Driver


=cut


=head1 SYNOPSIS

The driver does not connect to any external databases. Instead, it reads
all the SIAM objects from its YAML data file.

The top level element in the data file is expected to be an array of
objects that are contained in the SIAM root. The following object
classes are expected to be contained by the root object:

=over 4

=item * SIAM::Contract

=item * SIAM::AccessScope

=item * SIAM::User

=back

Each object definition may have an entry with the key C<_contains_>
which points to an array of contained objects. For example, an
C<SIAM::Contract> object is expected to contain one or more
C<SIAM::Service> objects.

All other keys in the object entry define the object attributes. The
values are expected to be strings and numbers. The data file should
define all the attributes, including C<object.id> and C<object.class>,
with a single exclusion for C<object.container_id> which is calculated
automatically.

See the file I<t/driver-simple.data.yaml> in SIAM package distribution
for reference.


=head1 MANDATORY METHODS

The following methods are required by C<SIAM::Documentation::DriverSpec>.


=head2 new

Instantiates a new driver object. The method expects a driver object and a hash
reference containing the attributes, as follows:

=over 4

=item * datafile

Full path of the YAML data file which defines all the objects for this driver.

=item * logger

Logger configuration as specified in C<Log::Handler> description.

=back

=cut

sub new
{
    my $class = shift;
    my $drvopts = shift;

    my $self = {};
    bless $self, $class;

    $self->{'config'} = $drvopts;
    
    foreach my $param ('datafile', 'logger')
    {
        if( not defined($drvopts->{$param}) )
        {
            print STDERR 
                ('Missing mandatiry parameter ' . $param .
                 ' in SIAM::Driver::Simple->new()');
            return undef;
        }
    }

    $self->{'logger'} = new Log::Handler($drvopts->{'logger'});

    if( not -r $self->{'config'}{'datafile'} )
    {
        $self->log->critical('Data file is not readable: ' .
                             $self->{'config'}{'datafile'});
        return undef;
    }

    $self->{'errmsg'} = '';
    
    return $self;    
}


=head2 connect

Reads the YAML data file

=cut

sub connect
{
    my $self = shift;

    my $yaml = new YAML;
    my $data = $yaml->LoadFile($self->{'config'}{'datafile'});
    if( not defined($data) )
    {
        $self->error('Cannot load YAML data from ' .
                     $self->{'config'}{'datafile'} . ': ' . $!);
        return undef;
    }
    
    if( ref($data) ne 'ARRAY' )
    {
        $self->error('Top level is not a sequence in ' .
                     $self->{'config'}{'datafile'});
        return undef;
    }

    $self->{'objects'} = {};
    $self->{'attr_index'} = {};
    $self->{'contains'} = {};
    $self->{'data_ready'} = 1;
    
    foreach my $obj (@{$data})
    {
        $self->_import_object($obj, 'SIAM.ROOT');
    }
    
    return $self->{'data_ready'};
}

# recursively import the objects

sub _import_object
{
    my $self = shift;
    my $obj = shift;
    my $container_id = shift;

    my $id = $obj->{'object.id'};
    if( not defined($id) )
    {
        $self->error($container_id .
                     ' contains an object without "object.id"' );
        $self->{'data_ready'} = 0;
        return;
    }

    my $class = $obj->{'object.class'};
    if( not defined($class) )
    {
        $self->error('Object ' . $id . ' does not have "object.class"' );
        $self->{'data_ready'} = 0;
        return;
    }
        
    # duplicate all attributes except "_contains_"

    my $dup = {};
    while( my ($key, $val) = each %{$obj} )
    {
        if( $key ne '_contains_' )
        {
            $dup->{$key} = $val;
            $self->{'attr_index'}{$class}{$container_id}{$key}{$val}{$id} = 1;
        }
    }
    
    $self->{'objects'}{$id} = $dup;    
    $self->{'contains'}{$class}{$container_id}{$id} = 1;

    if( defined($obj->{'_contains_'}) )
    {
        foreach my $contained_obj (@{$obj->{'_contains_'}})
        {
            $self->_import_object($contained_obj, $id);
        }
    }
}


=head2 disconnect

Disconnects the driver from its underlying databases.

=cut

sub disconnect
{
    my $self = shift;
    
    delete $self->{'objects'};
    delete $self->{'attr_index'};
    delete $self->{'contains'};
    $self->{'data_ready'} = 0;
}


=head2 fetch_attributes

 $status = $driver->fetch_attributes($attrs);

Retrieve the object by ID and populate the hash with object attributes.

=cut

sub fetch_attributes
{
    my $self = shift;
    my $obj = shift;

    my $id = $obj->{'object.id'};
    if( not defined($id) )
    {
        $self->error('object.id is not specified in fetch_attributes' );      
        return undef;
    }
    
    if( not defined($self->{'objects'}{$id}) )
    {
        $self->error('Object not found: ' . $id );      
        return undef;
    }

    while( my($key, $val) = each %{$self->{'objects'}{$id}} )
    {
        $obj->{$key} = $val;
    }
    
    return 1;
}
    


=head2 fetch_contained_object_ids

   $ids = $driver->fetch_contained_object_ids($id, 'SIAM::Contract', {
       'match_attribute' => [ 'object.access_scope_id',
                              ['SCOPEID01', 'SCOPEID02'] ]
      }
     );

Retrieve the contained object IDs.

=cut

sub fetch_contained_object_ids
{
    my $self = shift;
    my $container_id = shift;
    my $class = shift;
    my $options = shift;

    my $ret = [];

    if( defined($options) )
    {
        if( defined($options->{'match_attribute'}) )
        {
            my ($filter_attr, $filter_val) = @{$options->{'match_attribute'}};
            
            foreach my $val (@{$filter_val})                
            {
                push(@{$ret}, 
                     keys %{$self->{'attr_index'}{$class}{$container_id}{
                         $filter_attr}{$val}});
            }

            return $ret;
        }
    }
    
    if( defined($self->{'contains'}{$class}{$container_id}) )
    {
        push(@{$ret}, keys %{$self->{'contains'}{$class}{$container_id}});
    }

    return $ret;
}




=head2 errmsg

Returns the last error message.

=cut

sub errmsg {shift->{'errmsg'}}





=head1 ADDITIONAL METHODS

The following methods are not in the Specification.


=head2 debug

Prints a debug message to the logger

=cut

sub debug
{
    my $self = shift;
    my $msg = shift;
    
    $self->{'logger'}->debug($msg);
}


=head2 error

Prints an error message to the logger. Also saves the message for errmsg();

=cut

sub error
{
    my $self = shift;
    my $msg = shift;
    
    $self->{'logger'}->error($msg);
    $self->{'errmsg'} = $msg;
}









=head1 SEE ALSO

L<SIAM::Documentation::DriverSpec>, L<YAML>, L<Log::Handler>

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
