package Padre::Wx;

# Provides a set of Wx-specific miscellaneous functions

use 5.008;
use strict;
use warnings;
use File::Spec;
use File::ShareDir;
use Wx qw{
	wxBITMAP_TYPE_XPM
};

our $VERSION = '0.09';

sub _dir {
    return $ENV{PADRE_DEV}      ?  File::Spec->catdir($FindBin::Bin, '..', 'share')
         : $ENV{PADRE_PAR_PATH} ?  File::Spec->catdir($ENV{PADRE_PAR_PATH}, 'inc', 'share')
         :                         File::ShareDir::dist_dir('Padre')
         ;
}

sub bitmap {
    my $file = shift;
    my $dir  = _dir();
    my $path = File::Spec->catfile($dir , 'docview', "$file.xpm");
    return Wx::Bitmap->new( $path, wxBITMAP_TYPE_XPM );
}

sub icon {
    my $file = shift;
    my $dir  = _dir();
    my $path = File::Spec->catfile($dir , 'docview', "$file.xpm");
    return Wx::Icon->new( $path, wxBITMAP_TYPE_XPM );
}

1;
