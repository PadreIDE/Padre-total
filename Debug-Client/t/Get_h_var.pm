package Get_h_var;

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

sub help : Test(2) {
	my $self = shift;
	my $out;

	$out = $self->{debugger}->get_h_var();
	like( $out, qr/Control script execution/s, 'get_h_var() -> help menu' );

	$out = $self->{debugger}->get_h_var('h');
	like( $out, qr/Help.is.currently.only.available.for.the.new.5.8.command.set/s, 'get_h_var(h) -> 5.8 command set' );
}

# teardown methods are run after every test method.
sub teardown : Test(teardown) {
	my $self = shift;
	$self->{debugger}->quit;
	done_testing();
}


1;

__END__
