package t::lib::Breakpoints;

use base qw(Test::Class);
use Test::More;

use t::lib::Debugger;

# setup methods are run before every test method.
sub load_debugger : Test(setup) {
	my $self = shift;
	start_script('t/eg/03-return.pl');
	$self->{debugger} = start_debugger();
	$self->{debugger}->get;
}

sub bps : Test(7) {
	my $self = shift;

	$self->{debugger}->step_in;

	ok( $self->{debugger}->set_breakpoint( 't/eg/03-return.pl', 'g' ), 'set_breakpoint' );

	ok( $self->{debugger}->show_breakpoints() =~ m{t/eg/03-return.pl:}, 'show_breakpoints' );

	$self->{debugger}->run;

	#lets ask debugger where we are then :)
	like( $self->{debugger}->show_line(), qr/return.pl:22/, 'check breakpoint' );

	ok( $self->{debugger}->remove_breakpoint( 't/eg/03-return.pl', 'g' ), 'remove breakpoint' );

	ok( $self->{debugger}->show_breakpoints() =~ m{t/eg/03-return.pl:}, 'show_breakpoints' );

	ok( !$self->{debugger}->set_breakpoint( 't/eg/03-return.pl', 'missing' ), 'set_breakpoint against missing sub' );

	ok( !$self->{debugger}->set_breakpoint( 't/eg/03-return.pl', '03' ), 'set_breakpoint line not breakable' );

}

# teardown methods are run after every test method.
sub teardown : Test(teardown) {
	my $self = shift;
	$self->{debugger}->quit;
	done_testing();
}

1;

__END__
