package Padre::Wx;

# Provides a set of Wx-specific miscellaneous functions

use 5.008;
use strict;
use warnings;
use FindBin;
use File::Spec     ();
use File::ShareDir ();

# Load every exportable constant into here, so that they come into
# existance in the Wx:: package, allowing everywhere else in the code to
# use them without braces.
use Wx ':everything';

our $VERSION = '0.12';





#####################################################################
# Shared Resources

sub share () {
	return File::Spec->catdir( $FindBin::Bin, File::Spec->updir, 'share' ) if $ENV{PADRE_DEV};
	return File::Spec->catdir( $ENV{PADRE_PAR_PATH}, 'inc', 'share' )      if $ENV{PADRE_PAR_PATH};
	return File::ShareDir::dist_dir('Padre');
}

sub sharedir {
	File::Spec->catdir( share, @_ );
}

sub sharefile {
	File::Spec->catfile( share, @_ );
}





#####################################################################
# Load Shared Resources

sub bitmap {
	Wx::Bitmap->new(
		sharefile( 'docview', "$_[0].xpm" ),
		Wx::wxBITMAP_TYPE_XPM,
	);
}

sub icon {
	Wx::Icon->new(
		sharefile( 'docview', "$_[0].xpm" ),
		Wx::wxBITMAP_TYPE_XPM,
	);
}

1;
