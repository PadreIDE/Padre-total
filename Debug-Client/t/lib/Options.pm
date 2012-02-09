package t::lib::Options;

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
}

sub options : Test(5) {
	my $self = shift;
	my $out;
	$out = $self->{debugger}->get_options();
	ok( $out =~ m/CommandSet.=.'(\d+)'/s, 'get options' );
	diag("Info: ComamandSet = '$1'");

	$self->{debugger}->set_breakpoint( 't/eg/14-y_zero.pl', '14' );

	$out = $self->{debugger}->set_option('frame=2');
	like( $out, qr/frame.=.'2'/s, 'set options' );

	my @out;
	eval { $self->{debugger}->run };
	if ($@) {
		diag($@);
	} else {

		diag(@out);
		local $TODO = "Array ref request";
		# cmp_deeply(
		# \@out, [ 'main::', 't/eg/14-y_zero.pl', '14', 'print "$_ : $line \n";', ],
		# 'Array ref request'
		# );

	}

	$out = $self->{debugger}->set_option('frame=0');
	like( $out, qr/frame.=.'0'/s, 'reset options' );
	
	$out = $self->{debugger}->set_option();
	like( $out, qr/missing/s, 'missing option' );
}

# teardown methods are run after every test method.
sub teardown : Test(teardown) {
	my $self = shift;
	$self->{debugger}->quit;
	done_testing();
}

1;

__END__
