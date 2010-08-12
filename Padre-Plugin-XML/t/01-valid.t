#!perl

use Test::More tests => 3;

BEGIN {
	use_ok( 'Padre::Task::SyntaxChecker::XML' );
}

use File::Slurp;
my $c = read_file ('t/pad.xml');
my $res = Padre::Task::SyntaxChecker::XML::_valid('t/pad.xml',$c);
is(@$res,0,'2 errors found');
$c=~s#</XML_DIZ_INFO>#</XML_DIZ_INFO1>#;
$res = Padre::Task::SyntaxChecker::XML::_valid('t/pad.xml',$c);
is(@$res,1,'1 error found');
diag(@$res);
