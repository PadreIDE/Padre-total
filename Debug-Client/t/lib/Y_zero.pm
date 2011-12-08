package t::lib::Y_zero;

use base qw(Test::Class);
use Test::More;
use Test::Deep;

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

sub y_zero : Tests {
	my $self = shift;
	my @out;
	foreach ( 1 .. 3 ) {
		$self->{debugger}->run();

		my @out;
		@out = $self->{debugger}->get_y_zero();
		cmp_deeply( \@out, ["\$line = $_"], "y (0) \$line = $_" ) or diag( $self->{debugger}->buffer );

		# my $out = $self->{debugger}->get_value();
		# ok( $out == $_, "\$_ = $out" );
	}

	# ok( $self->{debugger}->get_x_vars('!(ENV|SIG|INC)') =~ m/14-y_zero.pl/, 'get_x_vars( !(ENV|SIG|INC) )' );
	# ok( $self->{debugger}->get_x_vars()                 =~ m/14-y_zero.pl/, 'get_x_vars()' );

}

# teardown methods are run after every test method.
sub teardown : Test(teardown) {
	my $self = shift;
	$self->{debugger}->quit;

	# done_testing();
}


1;

__END__
