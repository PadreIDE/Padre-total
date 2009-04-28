package Padre::Plugin::My;

use 5.008;
use strict;
use warnings;
use Padre::Config::Constants qw( $PADRE_CONFIG_DIR );
use Padre::Wx     ();
use Padre::Plugin ();

our $VERSION = '0.34';
use base 'Padre::Plugin';

#####################################################################
# Padre::Plugin Methods

sub padre_interfaces {
	'Padre::Plugin' => 0.24;
}

sub plugin_name {
	'My Plugin';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->show_about },

		# 'Another Menu Entry' => sub { $self->about },
		# 'A Sub-Menu...' => [
		#     'Sub-Menu Entry' => sub { $self->about },
		# ],
	];
}

#####################################################################
# Custom Methods

sub show_about {
	my $self = shift;

	# Locate this plugin
	my $path = File::Spec->catfile(
		$PADRE_CONFIG_DIR,
		qw{ plugins Padre Plugin My.pm }
	);

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("My Plugin");
	$about->SetDescription( <<"END_MESSAGE" );
The philosophy behind Padre is that every Perl programmer
should be able to easily modify and improve their own editor.

To help you get started, we've provided you with your own plugin.

It is located in your configuration directory at:
$path
Open it with with Padre and you'll see an explanation on how to add items.
END_MESSAGE

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

1;

__END__

=head1 NAME

Padre::Plugin::My - my personal plugin


=head1 DESCRIPTION

This is your personal plugin. Update it to fit your needs. And if it
does interesting stuff, please consider sharing it on CPAN!


=head1 COPYRIGHT & LICENSE

Currently it's copyright (c) 2008-2009 The Padre develoment team as
listed in Padre.pm... But update it and it will become Copyright (c) you
C<< you@your-domain.com> >>! How exciting! :-)


=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
