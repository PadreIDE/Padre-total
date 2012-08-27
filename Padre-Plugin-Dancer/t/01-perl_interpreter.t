use Test::More;

BEGIN {
	unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
		plan skip_all => 'Needs DISPLAY';
		exit 0;
	}
}
plan( tests => 2 );

use Padre::Perl;
use Padre::Plugin::Dancer;

ok( my $perl = Padre::Perl->perl, "Get perl interpreter" );
ok( defined $perl, "Perl interpreter defined" );

done_testing();

1;

__END__