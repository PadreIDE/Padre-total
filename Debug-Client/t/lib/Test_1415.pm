package t::lib::Test_1415;

use base qw(Test::Class);
use Test::More;
use Test::Deep;

use t::lib::Debugger;

# setup methods are run before every test method.
sub load_debugger : Test(setup) {
	my $self = shift;
	start_script('t/eg/test_1415.pl');
	$self->{debugger} = start_debugger();
	$self->{debugger}->get;
}

sub t1415 : Test(8) {
	my $self = shift;

	$self->{debugger}->__send( 'w' . '@fonts' );

	# diag( $self->{debugger}->__send('L w') );
	like( $self->{debugger}->__send('L w'), qr/fonts/, 'set watchpoints for @fonts' );

	#this is 'unlike' as it's a side affect of using a wantarry
	unlike( my @list = $self->{debugger}->run, qr/Watchpoint/, 'Watchpoint value changed' );

	like( $self->{debugger}->get_buffer, qr/fonts changed/, 'check buffer' );
	unlike( $self->{debugger}->module, qr/TERMINATED/, 'module still alive' );

	$self->{debugger}->get_lineinfo;
	like( $self->{debugger}->get_filename, qr/test_1415/, 'check where we are filename' );
	is( $self->{debugger}->get_row, 19, 'check where we are row' );
	like( $self->{debugger}->get_stack_trace(), qr/ANON/, 'O look, we are in an ANON sub' );

	#ToDo need a test for the value of @fonts
	# like( $self->{debugger}->get_value('@fonts'), qr/fred/, 'view contents of @fonts');
	# $self->{debugger}->get_value("@fonts");
	# diag( $self->{debugger}->get_buffer );
	# cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 7, 'my $y = 22;' ], 'view contents of @fonts' );


	like( $self->{debugger}->run, qr/Watchpoint/, 'stoped for watchpoint' );

}

# teardown methods are run after every test method.
sub teardown : Test(teardown) {
	my $self = shift;
	$self->{debugger}->quit;
	done_testing();
}

1;

__END__
