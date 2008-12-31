#!perl -T

use Test::More tests => 4;
use Parse::ErrorString::Perl;
use File::Spec;

my $parser = Parse::ErrorString::Perl->new;

my $path_script = File::Spec->catfile($INC[0], 'error.pl');
my $msg_short_script = 'Use of uninitialized value $empty in length at ' . $path_script . ' line 6.';

my @errors_short_script = $parser->parse_string($msg_short_script);
ok(@errors_short_script, 'msg_short_script results');
ok($errors_short_script[0]->file eq 'error.pl', 'msg_short_script short path');

our @INC;
my $path_module = File::Spec->catfile($INC[0], 'Error.pm');
my $msg_short_module = 'Use of uninitialized value $empty in length at ' . $path_module . ' line 6.';

my @errors_short_module = $parser->parse_string($msg_short_module);
ok(@errors_short_module, 'msg_short_module results');
ok($errors_short_module[0]->file eq 'Error.pm', 'msg_short_module short path');
