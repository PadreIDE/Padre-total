package t::lib::Subnames;

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

sub sub_names : Test(2) {
	my $self = shift;

	like( $self->{debugger}->list_subroutine_names(),         qr{Term::ReadLine}, 'S module' );
	like( $self->{debugger}->list_subroutine_names('strict'), qr{strict},         'S module plus regex' );

}

# teardown methods are run after every test method.
sub teardown : Test(teardown) {
	my $self = shift;
	$self->{debugger}->quit;
	done_testing();
}

1;

__END__
