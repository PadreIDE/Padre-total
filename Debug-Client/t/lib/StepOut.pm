package t::lib::StepOut;

use base qw(Test::Class);
use Test::More;
use Test::Deep;

use t::lib::Debugger;

# setup methods are run before every test method.
sub load_debugger : Test(setup) {
	my $self = shift;
	start_script('t/eg/02-sub.pl');
	$self->{debugger} = start_debugger();
	my $out = $self->{debugger}->get;
	$out =~ m/(1.\d{2})$/m;
	$self->{perl5db_ver} = $1;
}

sub stepout : Test(3) {
	my $self = shift;
	my $out;

	$self->{debugger}->run(18);
	
	my @out = $self->{debugger}->step_out;
	
	SKIP: {
		skip( "perl5db v$self->{perl5db_ver} dose not support list call", 1 ) unless $self->{perl5db_ver} < 1.35;
		cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 9, 'my $z = $x + $y;', 242 ], 'step_out to line 9' )
	}
	
	ok( $self->{debugger}->row == 9, 'row = 9');
	ok( $self->{debugger}->filename =~ m/02-sub/, 'filename = 02-sub.pl');

}

# teardown methods are run after every test method.
sub teardown : Test(teardown) {
	my $self = shift;
	$self->{debugger}->quit;
	done_testing();
}

1;

__END__
