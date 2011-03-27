#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'SIAM' ) || print "Bail out!
";
    use_ok( 'SIAM::Object' ) || print "Bail out!
";
}

diag( "Testing SIAM $SIAM::VERSION, Perl $], $^X" );
