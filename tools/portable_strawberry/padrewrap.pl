#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use File::Spec;


$ENV{PADRE_HOME}  = File::Spec->catdir( $FindBin::Bin, '..', '..' );
$ENV{PARROT_PATH} = File::Spec->catdir( $FindBin::Bin, '..', '..', 'parrot' );
#print $ENV{PADRE_HOME};
exec( $^X, File::Spec->catfile( $FindBin::Bin, 'padre' ) );
