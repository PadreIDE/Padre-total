#!perl -T

use Test::More tests => 33;
use Parse::ErrorString::Perl;

my $parser = Parse::ErrorString::Perl->new;

# use strict;
# use warnings;
#
# $hell;

my $msg_compile = <<'ENDofMSG';
Global symbol "$kaboom" requires explicit package name at error.pl line 8.
Execution of error.pl aborted due to compilation errors.
ENDofMSG

my @errors_compile = $parser->parse_string($msg_compile);
ok(@errors_compile, 'msg_compile results');
ok($errors_compile[0]->message eq 'Global symbol "$kaboom" requires explicit package name', 'msg_compile message');
ok($errors_compile[0]->file_msgpath eq 'error.pl', 'msg_compile file');
ok($errors_compile[0]->line == 8, 'msg_compile line');


# use strict;
# use warnings;
#
# my $empty;
# my $length = length($empty);
#
# my $zero = 0;
# my $result = 5 / 0;

my $msg_runtime = <<'ENDofMSG';
Use of uninitialized value $empty in length at error.pl line 5.
Illegal division by zero at error.pl line 8.
ENDofMSG

my @errors_runtime = $parser->parse_string($msg_runtime);
ok(@errors_runtime, 'msg_runtime results');
ok($errors_runtime[0]->message eq 'Use of uninitialized value $empty in length', 'msg_runtime 1 message');
ok($errors_runtime[0]->file_msgpath eq 'error.pl', 'msg_runtime 1 file');
ok($errors_runtime[0]->line == 5, 'msg_runtime 1 line');
ok($errors_runtime[1]->message eq 'Illegal division by zero', 'msg_runtime 2 message');
ok($errors_runtime[1]->file_msgpath eq 'error.pl', 'msg_runtime 2 file');
ok($errors_runtime[1]->line == 8, 'msg_runtime 2 line');

# use strict;
# use warnings;
#
# my $string = 'tada';
# kaboom
#
# my $length = 5;

my $msg_near = <<'ENDofMSG';
syntax error at error.pl line 7, near "kaboom

my "
Global symbol "$length" requires explicit package name at error.pl line 7.
Execution of error.pl aborted due to compilation errors.
ENDofMSG

my @errors_near = $parser->parse_string($msg_near);
ok(@errors_near, 'msg_near results');
ok($errors_near[0]->message eq 'syntax error', 'msg_near 1 message');
ok($errors_near[0]->file_msgpath eq 'error.pl', 'msg_near 1 file');
ok($errors_near[0]->line == 7, 'msg_near 1 line');
ok($errors_near[0]->near eq 'kaboom

my ', 'msg_near 1 near');
ok($errors_near[1]->message eq 'Global symbol "$length" requires explicit package name', 'msg_near 2 message');
ok($errors_near[1]->file_msgpath eq 'error.pl', 'msg_near 2 file');
ok($errors_near[1]->line == 7, 'msg_near 2 line');

#use strict;
#use warnings;
#
#if (1) { if (2)

my $msg_at = <<'ENDofMSG';
syntax error at error.pl line 4, at EOF
Missing right curly or square bracket at error.pl line 4, at end of line
Execution of error.pl aborted due to compilation errors.
ENDofMSG

my @errors_at = $parser->parse_string($msg_at);
ok(@errors_at, 'msg_at results');
ok($errors_at[0]->message eq 'syntax error', 'msg_at 1 message');
ok($errors_at[0]->file_msgpath eq 'error.pl', 'msg_at 1 file');
ok($errors_at[0]->line == 4, 'msg_at 1 line');
ok($errors_at[0]->at eq 'EOF', 'msg_at 1 at');
ok($errors_at[1]->message eq 'Missing right curly or square bracket', 'msg_at 2 message');
ok($errors_at[1]->file_msgpath eq 'error.pl', 'msg_at 2 file');
ok($errors_at[1]->line == 4, 'msg_at 2 line');
ok($errors_at[1]->at eq 'end of line', 'msg_at 2 at');

# use strict;
# use warnings;
#
# eval 'sub test {print}';
# test();

my $msg_eval = <<'ENDofMSG';
Use of uninitialized value $_ in print at (eval 1) line 1.
ENDofMSG

my @errors_eval = $parser->parse_string($msg_eval);
ok(@errors_eval, 'msg_eval results');
ok($errors_eval[0]->message eq 'Use of uninitialized value $_ in print', 'msg_eval 1 message');
ok($errors_eval[0]->file_msgpath eq '(eval 1)', 'msg_eval 1 file');
ok($errors_eval[0]->file eq 'eval', 'msg_eval 1 eval');
ok($errors_eval[0]->line == 1, 'msg_eval 1 line');

