#!/usr/bin/env perl

use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

use Test::More;
use Test::Deep;
plan( tests => 3 );

use t::lib::Debugger;
start_script('t/eg/14-y_zero.pl');
my $debugger = start_debugger();
$debugger->get;

subtest 'get_options' => sub {
	my $out;
	eval { $out = $debugger->get_options() };
	like( $out, qr/CommandSet.=.'580'/s ) or diag($out);
};

$debugger->set_breakpoint( 't/eg/14-y_zero.pl', '14' );

subtest 'set_option' => sub {
	my $out;
	eval { $out = $debugger->set_option('frame=2') };
	like( $out, qr/frame.=.'2'/s ) or diag($out);
};

# {
	# my @out;
	# eval { @out = $debugger->run };
	# cmp_deeply(
		# \@out, [ 'main::', 't/eg/14-y_zero.pl', '14', 'print "$_ : $line \n";', ],
		# 'module, file, row, content'
	# ) or diag(@out);
# }

subtest 'reset_option' => sub {
	my $out;
	eval { $out = $debugger->set_option('frame=0') };
	like( $out, qr/frame.=.'0'/s ) or diag($out);
};

$debugger->quit;

done_testing();

1;

__END__
