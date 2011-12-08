package t::lib::Get_p_exp;

use base qw(Test::Class);
use Test::More;

use t::lib::Debugger;

# setup methods are run before every test method.
sub load_debugger : Test(setup) {
	my $self = shift;
	start_script('t/eg/14-y_zero.pl');
	$self->{debugger} = start_debugger();
	$self->{debugger}->get;
	$self->{debugger}->set_breakpoint( 't/eg/14-y_zero.pl', '14' );
	$self->{debugger}->run;
}

sub get_p_expression : Test(7) {
	my $self = shift;

	foreach ( 1 .. 3 ) {
		$self->{debugger}->run();

		ok( $self->{debugger}->get_p_exp('$_')    =~ m/$_/, "p \$_ = $_" );
		ok( $self->{debugger}->get_p_exp('$line') =~ m/$_/, "p \$line = $_" );
	}
	ok( $self->{debugger}->get_p_exp('2 + 3') == 5, 'p 2 + 3 = 5' );
}

# teardown methods are run after every test method.
sub teardown : Test(teardown) {
	my $self = shift;
	$self->{debugger}->quit;
	done_testing();
}


1;

__END__
