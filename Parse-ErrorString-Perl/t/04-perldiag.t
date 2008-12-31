#!perl -T

use Test::More tests => 4;
use Parse::ErrorString::Perl;
use Test::Differences;


# use strict;
# use warnings;
#
# $hell;

my $msg_compile = <<'ENDofMSG';
Global symbol "$kaboom" requires explicit package name at error.pl line 8.
Execution of error.pl aborted due to compilation errors.
ENDofMSG

my $diagnostics = <<'ENDofMSG';
(F) You've said "use strict" or "use strict vars", which indicates 
that all variables must either be lexically scoped (using "my" or "state"), 
declared beforehand using "our", or explicitly qualified to say 
which package the global variable is in (using "::").
ENDofMSG

chomp($diagnostics);

my $parser = Parse::ErrorString::Perl->new;
my @errors_compile = $parser->parse_string($msg_compile);
is($errors_compile[0]->message, 'Global symbol "$kaboom" requires explicit package name', 'message');
#ok($errors_compile[0]->diagnostics eq $diagnostics, 'diagnostics');
eq_or_diff($errors_compile[0]->diagnostics, $diagnostics, 'diagnostics');
is($errors_compile[0]->type,              'F', 'type');
is($errors_compile[0]->type_description,  'fatal error', 'diagnostics');

