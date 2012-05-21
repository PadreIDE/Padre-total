use 5.010;
use Test::More;
plan( tests => 41 );

use_ok( 'Carp',                 '1.20' );
use_ok( 'IO::Socket',           '1.31' );
use_ok( 'IO::Socket::IP',       '0.10' );
use_ok( 'PadWalker',            '1.92' );
use_ok( 'Term::ReadLine',       '1.07' );
use_ok( 'Term::ReadLine::Perl', '1.0303' );

use_ok( 'Test::More',    '0.98' );
use_ok( 'Test::Deep',    '0.108' );
use_ok( 'Test::Class',   '0.36' );
use_ok( 'File::HomeDir', '0.98' );
use_ok( 'File::Temp',    '0.22' );
use_ok( 'File::Spec',    '3.33' );


######
# let's check our subs/methods.
######

my @subs = qw( buffer filename get get_h_var get_lineinfo get_options get_p_exp
	get_stack_trace get_v_vars get_value get_x_vars get_y_zero
	list_subroutine_names module new quit remove_breakpoint row run
	set_breakpoint set_option show_breakpoints show_line show_view show_line step_in step_over
	toggle_trace );

use_ok( 'Debug::Client', @subs );

foreach my $subs (@subs) {
	can_ok( 'Debug::Client', $subs );
}

done_testing();

1;

__END__
