package t::lib::Breakpoints;

use base qw(Test::Class);
use Test::More;
use Test::Deep;

use t::lib::Debugger;

# setup methods are run before every test method.
sub load_debugger : Test(setup) {
	my $self = shift;
	start_script('t/eg/03-return.pl');
	$self->{debugger} = start_debugger();
	$self->{debugger}->get;
}

sub options : Test(3) {
	my $self = shift;

	$self->{debugger}->step_in;

	ok( $self->{debugger}->set_breakpoint( 't/eg/03-return.pl', 'g' ), 'set_breakpoint' );

	ok( $self->{debugger}->show_breakpoints() =~ m{t/eg/03-return.pl:}, 'show_breakpoints' );

	my @out = $self->{debugger}->run;
	cmp_deeply( \@out, [ 'main::g', 't/eg/03-return.pl', 22, q{   my (@in) = @_;} ], 'run to breakpoint' );

}

# teardown methods are run after every test method.
sub teardown : Test(teardown) {
	my $self = shift;
	$self->{debugger}->quit;
	done_testing();
}

1;

__END__
