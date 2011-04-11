#!perl -T

use Test::More tests => 32;

use strict;
use warnings;
use File::Temp qw/tempfile/;
use YAML ();
use SIAM;
use SIAM::Driver::Simple;


my $config =
{
 'Driver' =>
 {
  'Class' => 'SIAM::Driver::Simple',
  'Options' =>
  {
   'datafile' => 't/driver-simple.data.yaml',
   'logger' =>
   {
    'screen' =>
    {
     'log_to'   => 'STDERR',
     'maxlevel' => 'warning',
     'minlevel' => 'emergency',
    },
   }
  },
 },
 'Root' =>
 {
  'Attributes' =>
  {
   'siam.enterprise_name' => 'XYZ Inc.',
   'siam.enterprise_url' => 'http://www.example.com',
   'siam.enterprise_logo_url' => 'http://www.example.com/logo.png'
  },
 },
};

note('loading SIAM');
ok( defined(my $siam = new SIAM($config)), 'load SIAM');

note('connecting the driver');
ok($siam->connect(), 'connect');

my $dataelement = $siam->instantiate_object('SIAM::ServiceDataElement',
                                            'SRVC0001.02.u01.d01');
ok(defined($dataelement), '$siam->instantiate_object');

### user: root
note('testing the root user');
my $user1 = $siam->get_user('root');
ok(defined($user1), 'get_user root');


note('checking that we retrieve all contracts');
my $all_contracts = $siam->get_all_contracts();
ok(scalar(@{$all_contracts}) == 2, 'get_all_contracts') or
    diag('Expected 2 contracts, got ' . scalar(@{$all_contracts}));


note('checking that root sees all contracts');
my $user1_contracts =
    $siam->get_contracts_by_user_privilege($user1, 'ViewContract');
ok(scalar(@{$all_contracts}) == scalar(@{$user1_contracts}),
   'get_contracts_by_user_privilege root') or
    diag('Expected ' . scalar(@{$all_contracts}) .
         ' contracts, got ' . scalar(@{$user1_contracts}));


### user: perpetualair
note('testing the user perpetualair');
my $user2 = $siam->get_user('perpetualair');
ok(defined($user1), 'get_user perpetualair');


note('checking that perpetualair sees only his contract');
my $user2_contracts =
    $siam->get_contracts_by_user_privilege($user2, 'ViewContract');
ok(scalar(@{$user2_contracts}) == 1,
   'get_contracts_by_user_privilege perpetualair') or
    diag('Expected 1 contract, got ' . scalar(@{$user2_contracts}));


my $x = $user2_contracts->[0]->attr('object.id');
ok($x eq 'CTRT0001', 'get_contracts_by_user_privilege perpetualair') or
    diag('Expected object.id: CTRT0001, got: ' . $x);



### user: zetamouse
note('testing the user zetamouse');
my $user3 = $siam->get_user('zetamouse');
ok(defined($user1), 'get_user zetamouse');


note('checking that zetamouse sees only his contract');
my $user3_contracts =
    $siam->get_contracts_by_user_privilege($user3, 'ViewContract');
ok(scalar(@{$user3_contracts}) == 1,
   'get_contracts_by_user_privilege zetamouse') or
    diag('Expected 1 contract, got ' . scalar(@{$user3_contracts}));


$x = $user3_contracts->[0]->attr('object.id');
ok($x eq 'CTRT0002', 'get_contracts_by_user_privilege zetamouse') or
    diag('Expected object.id: CTRT0002, got: ' . $x);


### Privileges
note('verifying privileges');
ok($user1->has_privilege('ViewContract', $user2_contracts->[0]) and
   $user1->has_privilege('ViewContract', $user3_contracts->[0]),
   'root->has_privilege') or
    diag('Root does not see a contract');

ok($user2->has_privilege('ViewContract', $user2_contracts->[0]) and
   $user3->has_privilege('ViewContract', $user3_contracts->[0]),
   'users see their contracts') or
    diag('one of users does not see his contract');

ok((not $user2->has_privilege('ViewContract', $user3_contracts->[0])),
   'perpetualair should not see contracts of zetamouse') or
    diag('perpetualair sees a contract of zetamouse');

ok((not $user3->has_privilege('ViewContract', $user2_contracts->[0])),
   'zetamouse should not see contracts of perpetualair') or
    diag('zetamouse sees a contract of perpetualair');



### Service units and data elements
note('testing the service units and data elements');

my $services = $user2_contracts->[0]->get_services();
ok(scalar(@{$services}) == 2, 'get_services') or
    diag('Expected 2 services for CTRT0001, got ' . scalar(@{$services}));

# find SRVC0001.01 for further testing
my $s;
foreach my $obj (@{$services})
{
    if( $obj->id() eq 'SRVC0001.01')
    {
        $s = $obj;
        last;
    }
}
ok(defined($s)) or diag('Expected to find Service SRVC0001.01');

my $units = $s->get_service_units();
ok(scalar(@{$units}) == 2, 'get_service_units') or
    diag('Expected 2 service units for SRVC0001.01, got ' .
         scalar(@{$units}));

# find SRVC0001.01.u01 for further testing
my $u;
foreach my $obj (@{$units})
{
    if( $obj->id() eq 'SRVC0001.01.u01' )
    {
        $u = $obj;
        last;
    }
}
ok(defined($u)) or diag('Expected to find Service Unit SRVC0001.01.u01');

my $dataelements = $u->get_data_elements();
ok(scalar(@{$dataelements}) == 1, 'get_data_elements') or
    diag('Expected 1 data element for SRVC0001.01.u01, got ' .
         scalar(@{$dataelements}));

### User privileges to see attributes
note('testing user privileges to see attributes');
my $filtered = $siam->filter_visible_attributes($user2, $u->attributes());

ok((not defined($filtered->{'access.bgp.peer.addr'}))) or
    diag('User perpetualair is not supposed to see access.bgp.peer.addr');

ok( defined($filtered->{'access.speed.downstream'})) or
    diag('User perpetualair is supposed to see access.speed.downstream');


### $object->contained_in()
note('testing $object->contained_in()');
my $x1 = $user2_contracts->[0]->contained_in();
ok(not defined($x1)) or
    diag('contained_in() did not return undef as expected');

my $x2 = $dataelement->contained_in();
ok(defined($x2)) or diag('contained_in() returned undef');

ok($x2->attr('object.class') eq 'SIAM::ServiceUnit') or
    diag('contained_in() returned object.class: ' . $x2->attr('object.class'));

ok($x2->id eq 'SRVC0001.02.u01') or
    diag('contained_in() returned object.id: ' . $x2->id);

### contract.content_md5hash
note('testing computable: contract.content_md5hash');
my $md5sum = $user2_contracts->[0]->computable('contract.content_md5hash');
ok(defined($md5sum) and $md5sum ne '') or
    diag('Computable contract.content_md5hash returned undef or empty string');

my $expected_md5 = 'a04984facd3492a127f20c42048a2155';
ok($md5sum eq $expected_md5) or
    diag('Computable contract.content_md5hash returned unexpected value: ' .
         $md5sum);

$siam->_driver->{'objects'}{'SRVC0001.02.u01.d01'}{'torrus.nodeid'} = 'xx';
ok($user2_contracts->[0]->computable('contract.content_md5hash') ne
   $expected_md5) or
    diag('Computable contract.content_md5hash did not change as expected');


### clone_data
note('testing SIAM::Driver::Simple->clone_data');
my ($fh, $filename) = tempfile();
binmode($fh, ':utf8');

ok(SIAM::Driver::Simple->clone_data($siam, $fh,
                                    {'SIAM::Contract' => '0002$'}));
$fh->close;
my $data = YAML::LoadFile($filename);
my $len = scalar(@{$data});
ok( $len == 18 ) or
    diag('clone_data is expected to produce array of size 18, got: ' . $len);

unlink $filename;

   



# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:

