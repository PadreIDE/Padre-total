use strict;
use warnings;

use t::lib::Debugger;


my ( $dir, $pid ) = start_script('t/eg/12-package.pl');

require Test::More;
import Test::More;
require Test::Deep;
import Test::Deep;

plan( tests => 2 );

diag("PID $pid");
my $debugger = start_debugger();
isa_ok( $debugger, 'Debug::Client' );

{
	my @out = $debugger->set_breakpoint( 't/eg/Test.pm', 'unique' );
	diag( explain(@out) );

	#	cmp_deeply( \@out, [ 'main::', 't/eg/01-add.pl', 6, 'my $x = 1;' ], 'line 6' )
	#		or diag( $debugger->buffer );
}

{
	my $out = $debugger->quit;
	like( $out, qr/1/, 'debugger quit' );
}

done_testing( );

1;

__END__
