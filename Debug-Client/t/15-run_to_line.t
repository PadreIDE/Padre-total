#!/usr/bin/env perl

use strict;
use warnings;

# no warnings 'once';
# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

use t::lib::Debugger;

my ( $dir, $pid ) = start_script('t/eg/02-sub.pl');

use Test::More;
use Test::Deep;

plan( tests => 4 );

my $debugger = start_debugger();
my $perl5db_ver;

{
	my $out = $debugger->get;

	$out =~ m/(1.\d{2})$/m;
	$perl5db_ver = $1;
	diag("Info: perl5db version $perl5db_ver");

	like( $out, qr/Loading DB routines from perl5db.pl version/, 'loading line' );
	like( $out, qr{main::\(t/eg/02-sub.pl:4\):\s*\$\| = 1;},     'line 4' );
}


{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 6, 'my $x = 11;' ], 'line 6' )
		or diag( $debugger->buffer );
}

SKIP: {
	skip( "perl5db $] dose not support c [line|sub]", 1 ) if $] =~ m/5.01500(3|4|5)/;SKIP: {
		skip( "perl5db v$perl5db_ver dose not support list context", 1 ) if $perl5db_ver == 1.35;
		my @out = $debugger->run(17);
		cmp_deeply( \@out, [ 'main::func1', 't/eg/02-sub.pl', 17, '   my $multi = $q * $w;' ], 'line 17' )
			or diag( $debugger->buffer );
	}
}

{
	$debugger->run;
	$debugger->quit;
}

done_testing();

1;

__END__
