package t::lib::Top_Tail;

use base qw(Test::Class);
use Test::More;
use Test::Deep;

# use t::lib::Debugger;

# setup methods are run before every test method.
sub top_tail : Test(7) {
	my $self = shift;

	use_ok( 'PadWalker', '1.92' );

	use_ok('t::lib::Debugger');

	ok( start_script('t/eg/14-y_zero.pl'), 'start script' );

	ok( $self->{debugger} = start_debugger(), 'start debugger' );

	ok( $self->{debugger}->get, 'get debugger' );

	like( $self->{debugger}->run, qr/Debugged program terminated/, 'Debugged program terminated' );

	like( $self->{debugger}->quit, qr/1/, 'debugger quit' );
}

1;

__END__
