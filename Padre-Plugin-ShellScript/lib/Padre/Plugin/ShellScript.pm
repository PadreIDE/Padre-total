package Padre::Plugin::ShellScript;

# ABSTRACT: Shell script support for Padre

use strict;
use warnings;
use 5.008;

use base 'Padre::Plugin';
use Wx ();
use File::Spec::Functions qw{ catfile };

# The plugin name to show in the Plugin Manager and menus
sub plugin_name {
	Wx::gettext('Shell Script');
}

# Declare the Padre interfaces this plugin uses
sub padre_interfaces {
	'Padre::Plugin' => 0.89, 'Padre::Document' => 0.89, 'Padre::Wx::Main' => 0.89;
}

sub registered_documents {
	'application/x-shellscript' => 'Padre::Document::ShellScript';
}

sub plugin_icon {
	my $self = shift;

	# find resource path
	my $iconpath = catfile( $self->plugin_directory_share, 'icons', 'gnome-mime-text-x-sh.png' );

	# create and return icon
	return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );
}

# The command structure to show in the Plugins menu
sub menu_plugins_simple {
	my $self = shift;
	'Shell Script' => [ Information => sub { $self->info() } ];
}

sub info {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName( Wx::gettext('Shell Script Plugin') );
	$about->SetDescription('Use the Run menu to run and debug shell scripts.');

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}
1;
__END__

=head1 NAME

Padre::Plugin::ShellScript - L<Padre> and ShellScript

=head1 AUTHOR

Claudio Ramirez C<< <padre.claudio@apt-get.be> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 Claudio Ramirez all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
