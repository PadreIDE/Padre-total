package t::lib::Recursive;

use base qw(Test::Class);
use Test::More;
use Test::Deep;

use t::lib::Debugger;

# setup methods are run before every test method.
sub load_debugger : Test(setup) {
	my $self = shift;
	start_script('t/eg/04-fib.pl');
	$self->{debugger} = start_debugger();
	my $out = $self->{debugger}->get;
	$out =~ m/(1.\d{2})$/m;
	$self->{perl5db_ver} = $1;
}

sub recursive : Test(5) {
	my $self = shift;
	my $out;
	my @out;
	
	$self->{debugger}->step_in;

	$out = $self->{debugger}->list_break_watch_action;
	like( $out, qr/^\s*DB<\d+> $/, 'no breakpoint in scalar context' );

	$self->{debugger}->set_breakpoint( 't/eg/04-fib.pl', 'fibx' );

	$out = $self->{debugger}->list_break_watch_action;
	ok( $out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl' );
	like( $out, qr/my \$n = shift/, 'list_break_wath_action in scalar context' );

	@out = $self->{debugger}->list_break_watch_action;
	cmp_deeply(
		\@out,
		[   3,
			[   {   file => 't/eg/04-fib.pl',
					line => 17,
					cond => 1,
				},
			]
		],
		'list_break_wath_action in list context'
	);

	$self->{debugger}->run;
	
	@out = $self->{debugger}->get_stack_trace;
	#pre v1.35 wanit this
	# my $trace1 = q($ = main::fibx(9) called from file `t/eg/04-fib.pl' line 12
# $ = main::fib(10) called from file `t/eg/04-fib.pl' line 22);

	#v1.35 and it works
	my $trace1 = q($ = main::fibx(9) called from file 't/eg/04-fib.pl' line 12
$ = main::fib(10) called from file 't/eg/04-fib.pl' line 22);

	SKIP: {
		skip( "perl5db less than v1.35 dose not support leading single quote' ", 1 ) if $self->{perl5db_ver} < 1.35;
	cmp_deeply( \@out, [$trace1], 'stack trace' )
}
	

}

# teardown methods are run after every test method.
sub teardown : Test(teardown) {
	my $self = shift;
	$self->{debugger}->quit;
	done_testing();
}

1;

__END__
