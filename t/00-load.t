#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'SIAM' ) || print "Bail out!
";
    use_ok( 'SIAM::Object' ) || print "Bail out!
";
    use_ok( 'SIAM::Driver::Simple' ) || print "Bail out!
";
}

diag( "Testing SIAM $SIAM::VERSION, Perl $], $^X" );
