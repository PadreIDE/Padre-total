package Padre::Plugin::YAML;

# ABSTRACT: YAML support for Padre

use v5.8.7;
use warnings;
use strict;

our $VERSION = '0.02';

use File::Spec::Functions qw{ catfile };

use base 'Padre::Plugin';
use Padre::Wx ();

sub plugin_name {
	return Wx::gettext('YAML');
}

sub padre_interfaces {
	return ( 'Padre::Plugin' => 0.91, 'Padre::Document' => 0.91 );
}

sub registered_documents {
	'text/x-yaml' => 'Padre::Document::YAML';
}

#sub plugin_icon {
#	my $self = shift;

# find resource path
#my $iconpath = catfile( $self->plugin_directory_share, 'icons', 'file.png' );

# create and return icon
#return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );
#}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('About') => sub { $self->show_about },
	];
}

#####################################################################
# Custom Methods

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName( Wx::gettext('YAML Plug-in') );
	my $authors     = 'Zeno Gantner';
	my $description = Wx::gettext( <<'END' );
YAML support for Padre

Copyright 2011 %s
This plug-in is free software; you can redistribute it and/or modify it under the same terms as Padre.
END
	$about->SetDescription( sprintf( $description, $authors ) );

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

1;
__END__

=head1 DESCRIPTION

YAML support for Padre, the Perl Application Development and Refactoring
Environment.

Syntax highlighting for YAML is supported by Padre out of the box.
This plug-in adds some more features to deal with YAML files.

=cut
