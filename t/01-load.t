#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use Class::Autouse ':devel';

ok( $] >= 5.008, 'Perl version is new enough' );

use_ok( 't::lib::Padre'      );
use_ok( 'Padre::Config'      );
use_ok( 'Padre'              );
use_ok( 'Padre::Project'     );
use_ok( 'Padre::DB'          );
use_ok( 'Padre::Pod::Viewer' );
use_ok( 'Padre::Demo'        );
