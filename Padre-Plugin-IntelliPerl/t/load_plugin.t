#!perl

use Test::More;

if ( defined( $ENV{DISPLAY} ) or $^O eq 'MSWin32' ) {
	plan tests => 3;
} else {
	plan skip_all => "this test needs DISPLAY";
}

use Padre;
use Padre::PluginManager;

my $p = Padre->new();
my $m = Padre::PluginManager->new();
$m->load_plugin("IntelliPerl");
isnt( $m->{plugins}->{IntelliPerl}->{status}, 'error' );

SKIP: {
	if ( $m->{plugins}->{IntelliPerl}->{status} eq 'error' ) {
		warn( "failed to load: " . $m->{plugins}->{IntelliPerl}->{errstr} );
		skip "failed to load: " . $m->{plugins}->{IntelliPerl}->{errstr}, 2;
	}

	ok( $m->{plugins}->{IntelliPerl}->enable() );
	is( $m->{plugins}->{IntelliPerl}->{status}, 'enabled' );
}
