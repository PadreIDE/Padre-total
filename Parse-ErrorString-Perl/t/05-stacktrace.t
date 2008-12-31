#!perl -T

use Test::More tests => 8;
use Parse::ErrorString::Perl;


# use strict;
# use warnings;
# use diagnostics '-traceonly';
#  
# sub dying { my $illegal = 10 / 0;}
# sub calling {dying()}
# 
# calling();


my $msg = <<'ENDofMSG';
Uncaught exception from user code:
	Illegal division by zero at error.pl line 5.
 at error.pl line 5
	main::dying() called at error.pl line 6
	main::calling() called at error.pl line 8
ENDofMSG

my $parser = Parse::ErrorString::Perl->new;
my @errors = $parser->parse_string($msg);
ok(@errors, 'message results');
my @stacktrace = $errors[0]->stack;
ok(@stacktrace, 'stacktrace results');
ok($stacktrace[0]->sub eq 'main::dying()', 'stack 1 sub');
ok($stacktrace[0]->file_msgpath eq 'error.pl', 'stack 1 file_msgpath');
ok($stacktrace[0]->line == 6, 'stack 1 line');
ok($stacktrace[1]->sub eq 'main::calling()', 'stack 2 sub');
ok($stacktrace[1]->file_msgpath eq 'error.pl', 'stack 2 file_msgpath');
ok($stacktrace[1]->line == 8, 'stack 2 line');


