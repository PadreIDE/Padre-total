package t::lib::Get_v_vars;

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

sub get_v_variables : Test(2) {
	my $self = shift;

	ok( $self->{debugger}->get_v_vars('$0') =~ m/14-y_zero.pl/, 'V $0' );
	ok( $self->{debugger}->get_v_vars()     =~ m/14-y_zero.pl/, 'V' );

}

# teardown methods are run after every test method.
sub teardown : Test(teardown) {
	my $self = shift;
	$self->{debugger}->quit;
	done_testing();
}


1;

__END__
