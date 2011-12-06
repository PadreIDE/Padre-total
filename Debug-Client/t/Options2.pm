package Options2;

use base qw(Test::Class);
use Test::More;

use t::lib::Debugger;

# setup methods are run before every test method.
sub load_debugger : Test(setup) {
	my $self = shift;
	start_script('t/eg/14-y_zero.pl');
	$self->{debugger} = start_debugger();
	$self->{debugger}->get;
}

sub options : Test(3) {
	my $self = shift;
	my $out;
	$out = $self->{debugger}->get_options();
	like( $out, qr/CommandSet.=.'580'/s, 'get options' ) or diag($out);

	$self->{debugger}->set_breakpoint( 't/eg/14-y_zero.pl', '14' );

	$out = $self->{debugger}->set_option('frame=2');
	like( $out, qr/frame.=.'2'/s, 'set options' ) or diag($out);

	$out = $self->{debugger}->set_option('frame=0');
	like( $out, qr/frame.=.'0'/s, 'reset options' ) or diag($out);
}

# teardown methods are run after every test method.
sub teardown : Test(teardown) {
	my $self = shift;
	$self->{debugger}->quit;
	done_testing();
}

1;

__END__
