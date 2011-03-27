package SIAM::Object;

use warnings;
use strict;

our $is_error = 0;
our $errmsg = '';
our $logmgr;

=head1 NAME


SIAM::Object - the base class for all SIAM object (including the root).


=cut


=head1 SYNOPSIS



=head1 INSTANCE METHODS

=head2 new

  $new_object = new SIAM::Object($driver, $attributes)

Instantiates a new object. The method expects a driver object and a hash
reference containing the attributes, as follows:

=over 4

=item * object.id

=back

=cut

sub new
{
    my $class = shift;
    my $driver = shift;
    my $attributes = shift;

    my $self = {};
    bless $self, $class;

    $self->{'_attr'} = {};
    foreach my $attr ('object.id')
    {
        if( defined($attributes->{$attr}) )
        {
            $self->{'_attr'}{$attr} = $attributes->{$attr};
        }
        else
        {
            SIAM::Object->critical
                  ('Missing mandatiry attribute ' . $attr .
                   ' in SIAM::Object->new()');
            return undef;
        }
    }
    
    $self->{'_attr'}{'object.class'} = $class;
    $self->{'_driver'} = $driver;

    # retrieve attributes from the driver unless I am root
    if( not $self->is_root )
    {
        if( not $driver->fetch_attributes($self->{'_attr'}) )
        {
            SIAM::Object->error($driver->errmsg);
            return undef;
        }
    }

    return $self;    
}



=head2 get_contained_objects

 my $list = $object->get_contained_objects($classname);

Fetches the list of contained objects of a given class. Returns arrayref of
C<SIAM::Object> instances. This is the preferred method of instantiating new
objects instead of manually calling the C<new> method.

It is assumed that the class name is already known to Perl, and the
corresponding module was loaded with C<use> or C<require>.

=cut

sub get_contained_objects
{
    my $self = shift;
    my $classname = shift;

    my $ids =
        $self->_driver->fetch_contained_object_ids($self->id, $classname);
    my $driver = $self->_driver;
    
    my $ret = [];
    foreach my $id (@{$ids})
    {
        my $attributes = {'object.id' => $id};
        my $obj = eval($classname . '->new($driver, $attributes)');

        if( $@ )
        {
            SIAM::Object->critical($@);
        }
        elsif( defined($obj) )
        {
            push(@{$ret}, $obj);
        }
    }

    return $ret;
}


=head2 id

Returns a value of C<object.id> attribute

=cut

sub id { shift->attr('object.id') }


=head2 attr

 $val = $contract->attr('contract.inventory_id');

Returns a value of an attribute.

=cut

sub attr { shift->{'_attr'}{shift} }


=head2 is_root

Returns true if the object is a root.

=cut

sub is_root { shift->id eq 'ROOT' }



=head1 CLASS METHODS

=head2 validate_driver

Takes a driver object as an argument and verifies if it implements all
required methods. returns true if all required methods are present. It
issues critical error messages in case of missing methods.

=cut

sub validate_driver
{
    my $class = shift;
    my $driver = shift;

    my $ok = 1;
    foreach my $m ('fetch_attributes', 'fetch_contained_object_ids',
                   'errmsg', 'connect', 'disconnect')
    {
        if( not $driver->can($m) )
        {
            SIAM::Object->critical
                  ('The driver of class ' . ref($driver) . 'does not ' .
                   'implement a required method: ' . $m);
            $ok = 0;
        }
    }

    return $ok;
}




=head2 is_error

Returns true in case of an error;

=cut

sub is_error { $is_error }



=head2 errmsg

Returns the error string with the error details.

=cut

sub errmsg { $errmsg }



=head2 set_log_manager

Sets a log manager. Unless a log manager is set, all warnings and errors
are sent to STDERR. The method expects one argument, an object which
implements the following methods:

=over 4

=item * debug

=item * info

=item * warn, warning

=item * error, err

=item * critical, fatal

=back

Classes that suit as log managers: C<Log::Handler>, C<Log::Log4perl>, ...

=cut

sub set_log_manager
{
    my $class = shift;
    $logmgr = shift;
}


=head2 debug, info, warning, error, critical

These methods dispatch a message to the log manager. If the log manager
is undefined, all except C<debug()> print the message to STDERR with a
preceeding timestamp.

C<error()> and C<critical()> also set the error status and error message.

=cut

sub debug
{
    my $class = shift;
    my $msg = shift;
    if( defined($logmgr) and $logmgr->can('debug') )
    {
        $logmgr->debug($msg);
    }
}

sub info
{
    my $class = shift;
    my $msg = shift;
    if( defined($logmgr) )
    {
        if( $logmgr->can('info') )
        {
            $logmgr->info($msg);
        }
    }
    else
    {
        SIAM::Object->_print_stderr('INFO: ' .$msg);
    }
}

sub warning
{
    my $class = shift;
    my $msg = shift;

    my $dispatched = 0;
    if( defined($logmgr) )
    {
        if( $logmgr->can('warn') )
        {
            $logmgr->warn($msg);
            $dispatched = 1;
        }
        elsif( $logmgr->can('warning') )
        {
            $logmgr->warning($msg);
            $dispatched = 1;
        }
    }

    # warnings are important -- fall back to STDERR
    if( not $dispatched )
    {
        SIAM::Object->_print_stderr('WARNING: ' . $msg);
    }
}

sub error
{
    my $class = shift;
    my $msg = shift;

    $is_error = 1;
    $errmsg = $msg;
    
    my $dispatched = 0;
    if( defined($logmgr) )
    {
        if( $logmgr->can('error') )
        {
            $logmgr->error($msg);
            $dispatched = 1;
        }
        elsif( $logmgr->can('err') )
        {
            $logmgr->err($msg);
            $dispatched = 1;
        }
    }

    # errors are important -- fall back to STDERR
    if( not $dispatched )
    {
        SIAM::Object->_print_stderr('ERROR: ' . $msg);
    }
}

sub critical
{
    my $class = shift;
    my $msg = shift;

    $is_error = 1;
    $errmsg = $msg;
    my $dispatched = 0;
    if( defined($logmgr) )
    {
        if( $logmgr->can('critical') )
        {
            $logmgr->critical($msg);
            $dispatched = 1;
        }
        elsif( $logmgr->can('fatal') )
        {
            $logmgr->fatal($msg);
            $dispatched = 1;
        }
    }
    
    # Critical errors are important -- fall back to STDERR
    if( not $dispatched )
    {
        SIAM::Object->_print_stderr('CRITICAL: ' . $msg);
    }
}



=head1 PRIVATE METHODS

=head2 _driver

Returns the driver object

=cut

sub _driver { shift->{'_driver'} }


=head2 _print_stderr

Prints a message to STDERR with a preceeding timestamp

=cut

sub _print_stderr
{
    my $class = shift;
    my $msg = shift;

    print STDERR scalar(localtime(time())) . ' ' . $msg;
}



1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-brace-offset: -4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: 0
# End:
