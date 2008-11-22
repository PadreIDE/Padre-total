package Padre::Wx;

# Provides a set of Wx-specific miscellaneous functions

use 5.008;
use strict;
use warnings;
use FindBin;
use File::Spec ();

# Load every exportable constant into here, so that they come into
# existance in the Wx:: packages, allowing everywhere else in the code to
# use them without braces.
use Wx         ':everything';
use Wx::Event  ':everything';
use Wx::STC    ();
use Wx::AUI    ();
use Wx::Locale ':default';

our $VERSION = '0.17';





#####################################################################
# Defines for sidebar marker; others may be needed for breakpoint
# icons etc.

sub MarkError { 1 }
sub MarkWarn  { 2 }





#####################################################################
# Defines for object IDs

sub id_SYNCHK_TIMER  { 30001 }
sub id_FILECHK_TIMER { 30002 }





#####################################################################
# Shared Resources

sub share () {
	return File::Spec->catdir( $FindBin::Bin, File::Spec->updir, 'share' ) if $ENV{PADRE_DEV};
	return File::Spec->catdir( $ENV{PADRE_PAR_PATH}, 'inc', 'share' )      if $ENV{PADRE_PAR_PATH};
	require File::ShareDir::PAR;
	return File::ShareDir::PAR::dist_dir('Padre');
}

sub sharedir {
	File::Spec->catdir( share(), @_ );
}

sub sharefile {
	File::Spec->catfile( share(), @_ );
}





#####################################################################
# Load Shared Resources

sub tango {
	Wx::Bitmap->new(
		sharefile( 'tango', '16x16', @_ ),
		Wx::wxBITMAP_TYPE_PNG,
	);
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
