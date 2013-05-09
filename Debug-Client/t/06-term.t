use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use version;
use Test::More tests => 14;

BEGIN {
	use_ok( 'Term::ReadKey',  '2.30' );
	use_ok( 'Term::ReadLine', '1.04' );
}

diag("\nInfo: Perl $PERL_VERSION");
diag("Info: OS $OSNAME");

SKIP: {
	skip 'Skipping Columns & Lines as we are running on win32', 2 if $OSNAME ne 'MSWin32';
	is( $ENV{COLUMNS}, undef, '$ENV{COLUMS} is undefined' );
	is( $ENV{LINES},   undef, '$ENV{LINES} is undefined' );
}

is( $ENV{PERL_RL}, undef, '$ENV{PERL_RL} is undefined' );

{
	eval 'use Term::ReadLine::Perl';
	if ($EVAL_ERROR) {
		diag 'Info: Term::ReadLine::Perl is not installed';
	} else {
		diag 'Info: Term::ReadLine::Perl installed';
	}
}

SKIP: {
	eval { require Term::ReadLine::Perl };
	skip 'Term::ReadLine::Perl not installed', 2 if $EVAL_ERROR;
	use_ok('Term::ReadLine::Perl');
	cmp_ok( version->parse($Term::ReadLine::Perl::VERSION), 'ge', 0, 'Term::ReadLine::Perl version = ' . version->parse($Term::ReadLine::Perl::VERSION) );
}

{
	eval 'use Term::ReadLine::Perl5';
	if ($EVAL_ERROR) {
		diag 'Info: Term::ReadLine::Perl5 is not installed';
	} else {
		diag 'Info: Term::ReadLine::Perl5 installed';
	}
}

SKIP: {
	eval { require Term::ReadLine::Perl5 };
	skip 'Term::ReadLine::Perl5 not installed', 2 if $EVAL_ERROR;
	use_ok('Term::ReadLine::Perl5');
	cmp_ok( version->parse($Term::ReadLine::Perl5::VERSION), 'ge', 0,
		'Term::ReadLine::Perl5 version = ' . version->parse($Term::ReadLine::Perl5::VERSION) );
}

{
	eval 'use Term::ReadLine::Gnu';
	if ($EVAL_ERROR) {
		diag 'Info: Term::ReadLine::Gnu is not installed';
	} else {
		diag 'Info: Term::ReadLine::Gnu installed';
	}
}

SKIP: {
	eval { require Term::ReadLine::Gnu };
	skip 'Term::ReadLine::Gnu not installed', 2 if $EVAL_ERROR;
	use_ok('Term::ReadLine::Gnu');
	cmp_ok( version->parse($Term::ReadLine::Gnu::VERSION), 'ge', 0,
		'Term::ReadLine::Gnu version = ' . version->parse($Term::ReadLine::Gnu::VERSION) );

}

{
	eval 'use Term::ReadLine::EditLine';
	if ($EVAL_ERROR) {
		diag 'Info: Term::ReadLine::EditLine is not installed';
	} else {
		diag 'Info: Term::ReadLine::EditLine installed';
	}
}

SKIP: {
	eval { require Term::ReadLine::EditLine };
	skip 'Term::ReadLine::EditLine not installed', 2 if $EVAL_ERROR;
	use_ok('Term::ReadLine::EditLine');
	cmp_ok( version->parse($Term::ReadLine::EditLine::VERSION), 'ge', 0,
		'Term::ReadLine::EditLine version = ' . version->parse($Term::ReadLine::EditLine::VERSION) );
}

{
	my $term;
	eval { $term = Term::ReadLine->new('none') };
	if ($EVAL_ERROR) {
		diag 'Warning: If test fail consider installing Term::ReadLine::Gnu' if $OSNAME ne 'MSWin32';
	} else {
		diag 'Info: Using ReadLine implementation -> ' . $term->ReadLine;
	}
}

# Patch for Debug::Client ticket #831 (MJGARDNER)
# Turn off ReadLine ornaments
##local $ENV{PERL_RL} = ' ornaments=0';
##$ENV{TERM} = 'dumb' if ! exists $ENV{TERM};
diag 'INFO: $ENV{TERM} -> ' . $ENV{TERM} . "\n" if defined $ENV{TERM};
ok( $ENV{TERM} !~ /undef/, '$ENV{TERM} is set to -> ' . $ENV{TERM} );


done_testing();

__END__
