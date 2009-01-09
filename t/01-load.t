#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

#use Test::NeedsDisplay ':skip_all';
use Test::More;
BEGIN {
	if (not $ENV{DISPLAY} and not $^O eq 'MSWin32') {
		plan skip_all => 'Needs DISPLAY';
		exit 0;
	}
}
plan( tests => 23 );
use Test::Script;
use Test::NoWarnings;
use Class::Autouse ':devel';

ok( $] >= 5.008, 'Perl version is new enough' );

use_ok( 'Wx'                             );
diag( "Tests find Wx: $Wx::VERSION " . Wx::wxVERSION_STRING() );

use_ok( 't::lib::Padre'                    );
use_ok( 'Padre::Util'                      );
use_ok( 'Padre::Config'                    );
use_ok( 'Padre::DB'                        );
use_ok( 'Padre::DB::Patch'                 );
use_ok( 'Padre::Project'                   );
use_ok( 'Padre::Wx'                        );
use_ok( 'Padre::Wx::HtmlWindow'            );
use_ok( 'Padre::Wx::Printout'              );
use_ok( 'Padre::Wx::Dialog::PluginManager' );
use_ok( 'Padre::Wx::Dialog::Preferences'   );
use_ok( 'Padre::Wx::History::TextDialog'   );
use_ok( 'Padre::Wx::History::ComboBox'     );
use_ok( 'Padre'                            );
use_ok( 'Padre::Pod2HTML'                  );
use_ok( 'Padre::Plugin::Devel'             );
use_ok( 'Padre::Plugin::My'                );

script_compiles_ok('script/padre');
script_compiles_ok('share/timeline/migrate-1.pl');
script_compiles_ok('share/timeline/migrate-2.pl');
