#!/usr/bin/env perl

use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

use Test::More;
use Test::Deep;
my $PROMPT = re('^\d+$');

# Testing some of the internal methods

use Debug::Client;


my @tests;
push @tests, {
	out => q(Loading DB routines from perl5db.pl version 1.28
Editor support available.

Enter h or `h h' for help, or `man perldebug' for more help.

main::(t/eg/01-add.pl:4):	$| = 1;
  DB<1> ),
	exp => [ $PROMPT, 'main::', 't/eg/01-add.pl', 4, '$| = 1;' ],
};

# I saw this kind of output when using Padre, I am not sure
# why is the row number repeated and why is the content on a new line
push @tests, {
	out => q(Loading DB routines from perl5db.pl version 1.3
Editor support available.

Enter h or `h h' for help, or `man perldebug' for more help.

main::(/home/gabor/work/padre/Debug-Client/t/eg/01-add.pl:4):
4:	$| = 1;
  DB<1> ),
	exp => [ $PROMPT, 'main::', '/home/gabor/work/padre/Debug-Client/t/eg/01-add.pl', 4, '$| = 1;' ],
};


# Strawberry Perl on Windows
push @tests, {
	out => q(Loading DB routines from perl5db.pl version 1.32
Editor support available.

Enter h or `h h' for help, or `perldoc perldebug' for more help.

main::(d:\work\padre\Debug-Client\t\eg\01-add.pl:4):
4:	$| = 1;
  DB<1> ),
	exp => [ $PROMPT, 'main::', 'd:\work\padre\Debug-Client\t\eg\01-add.pl', 4, '$| = 1;' ],
};

push @tests, {
	out => q(Debugged program terminated.  Use q to quit or R to restart,
  use o inhibit_exit to avoid stopping after program termination,
  h q, h R or h o to get additional info.  
  DB<1> ),
	exp => [ $PROMPT, '<TERMINATED>' ],
};

plan tests => 2 + scalar @tests;

my $debugger = Debug::Client->new;
foreach my $tests (@tests) {
	my $out    = $tests->{out};
	my $prompt = $debugger->_prompt( \$out );
	my @res    = $debugger->_process_line( \$out );
	cmp_deeply( [ $prompt, @res ], $tests->{exp} );
}

eval { $debugger->_prompt(); };
like($@, qr{_prompt should be called with a reference to a scalar}, '_prompt without param');

eval { $debugger->_prompt('hello'); };
like($@, qr{_prompt should be called with a reference to a scalar}, '_prompt without param');

done_testing( );

1;

__END__
