package Padre::Plugin::Ecliptic;

use strict;
use warnings;

# exports and version
our $VERSION = '0.01';
our @EXPORT_OK = ();

use Padre::Wx ();
use Padre::Util   ('_T');
use base 'Padre::Plugin';

# private subroutine to return the current share directory location
sub _sharedir {
	return Cwd::realpath(File::Spec->join(File::Basename::dirname(__FILE__),'Ecliptic/share'));
}

# Returns the plugin name to Padre
sub plugin_name {
	return _T("Ecliptic");
}

# directory where to find the translations
sub plugin_locale_directory {
	return File::Spec->catdir( _sharedir(), 'locale' );
}

sub padre_interfaces {
	return 'Padre::Plugin' => 0.26,
}

# plugin icon
sub plugin_icon {
    # find resource path
    my $iconpath = File::Spec->catfile( _sharedir(), 'icons', 'ecliptic.png');

    # create and return icon
    return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );
}

# called when the plugin is enabled
sub plugin_enable {
	my $self = shift;

	return 1;
}

# called when Padre needs the plugin's menu
sub menu_plugins {
	my $self        = shift;
	my $main_window = shift;

	# Create a simple menu with a single About entry
	$self->{menu} = Wx::Menu->new;

	# the famous about menu item...
	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, _T("About"), ),
		sub { $self->show_about },
	);

	# Return our plugin with its label
	return ( $self->plugin_name => $self->{menu} );
}

sub show_about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Ecliptic");
	$about->SetDescription(
		_T("Provides useful Eclipse-like to Padre.\n") .
		
	);
	$about->SetVersion($VERSION);
	Wx::AboutBox( $about );
	return;
}

1;

__END__

=head1 NAME

Padre::Plugin::Ecliptic - Padre plugin for Eclipse-like features

=head1 SYNOPSIS

After installation when you run Padre there should be a menu option Plugins/Ecliptic.

=head1 AUTHOR

Ahmad M. Zawawi, C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT

Copyright 2009 Ahmad M. Zawawi, C<< <ahmad.zawawi at gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
