package t::lib::StepIn;

use base qw(Test::Class);
use Test::More;
use Test::Deep;

use t::lib::Debugger;
use Data::Printer { caller_info => 1, colored => 1, };

# setup methods are run before every test method.
sub load_debugger : Test(setup) {
	my $self = shift;
	start_script('t/eg/02-sub.pl');
	$self->{debugger} = start_debugger();
	my $out = $self->{debugger}->get;
	$out =~ m/(1.\d{2})$/m;
	$self->{perl5db_ver} = $1;
}

sub stepin : Test(4) {
	my $self = shift;
	my $out;

	$out = $self->{debugger}->step_in;
	like( $out, qr{sub.pl:6}, 'step to line 6' );
	
	my @out = $self->{debugger}->step_in;
	
	SKIP: {
		skip( "perl5db v$self->{perl5db_ver} dose not support list call", 1 ) unless $self->{perl5db_ver} < 1.35;
		cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 7, 'my $y = 22;' ], 'step to line 7' );
	}
	
	ok( $self->{debugger}->row == 7, 'row = 7');
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
