package t::lib::GetValue;

use base qw(Test::Class);
use Test::More;
use Test::Deep;

use t::lib::Debugger;

# setup methods are run before every test method.
sub load_debugger : Test(setup) {
	my $self = shift;
	start_script('t/eg/02-sub.pl');
	$self->{debugger} = start_debugger();
	$self->{debugger}->get;
}

sub get_value : Test(6) {
	my $self = shift;

	my @out;
	my $out;

	$self->{debugger}->step_in;
	$self->{debugger}->step_in;
	
	$out = $self->{debugger}->get_value();
	is( $out, '', 'nought' );

	$out = $self->{debugger}->get_value('19+23');
	cmp_ok( $out, '==', '42', '19+23=42 the answer' );

	$self->{debugger}->__send('$abc = 23');
	$out = $self->{debugger}->get_value('$abc');
	cmp_ok( $out, '==', '23', 'we just set a variable $abc = 23' );

	$self->{debugger}->__send('@qwe = (23, 42)');
	$out = $self->{debugger}->get_value('@qwe');
	like( $out, qr/42/, 'get_value of array' );


	$out = $self->{debugger}->get_value('%h');
	like( $out, qr/empty hash/, 'empty hash' );

	$self->{debugger}->__send_np('%h = (fname => "foo", lname => "bar")');

	$out = $self->{debugger}->get_value('%h');
	like( $out, qr/bar/, 'hash' );

}

# teardown methods are run after every test method.
sub teardown : Test(teardown) {
	my $self = shift;
	$self->{debugger}->quit;
	done_testing();
}


1;

__END__
