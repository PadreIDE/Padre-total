#!perl

use Test::More tests => 5;

BEGIN {
	use_ok( 'Padre::Task::SyntaxChecker::XML' );
}

use File::Slurp;
my $c = read_file ('t/pad.xml');
my $res = Padre::Task::SyntaxChecker::XML::_valid('t/pad.xml',$c);
is(@$res,0,'2 errors found');
$c=~s#</XML_DIZ_INFO>#</XML_DIZ_INF>#;
$res = Padre::Task::SyntaxChecker::XML::_valid('t/pad.xml',$c);
is(@$res,1,'1 error found');
like($res->[0]{msg},qr/parser error : Opening and ending tag mismatch/);
is($res->[0]{line},124);
#diag(join(', ',%{$res->[0]}));
