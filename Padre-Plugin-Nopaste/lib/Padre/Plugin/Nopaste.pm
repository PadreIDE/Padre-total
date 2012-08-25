#
# This file is part of Padre::Plugin::Nopaste.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Padre::Plugin::Nopaste;

use v5.10;
use strict;
use warnings;
our $VERSION = '0.4';

use parent qw{
	Padre::Plugin
	Padre::Role::Task
};

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

# use Data::Printer {
# caller_info => 1,
# colored     => 1,
# };


# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::Nopaste
	Padre::Plugin::Nopaste::Task
	App::Nopaste
	App::Nopaste::Service
	App::Nopaste::Service::Shadowcat
};


#######
# Define Plugin Name Spell Checker
#######
sub plugin_name {
	return Wx::gettext('Nopaste');
}

#######
# Define Padre Interfaces required
#######
sub padre_interfaces {
	return (
		'Padre::Plugin' => '0.94',
		'Padre::Task'   => '0.94',
		'Padre::Unload' => '0.94',

		# used by my sub packages
		# 'Padre::Locale'         => '0.96',
		# 'Padre::Logger' => '0.94',

		# 'Padre::Wx'             => '0.96',
		# 'Padre::Wx::Role::Main' => '0.96',
		# 'Padre::Util'           => '0.97',
	);
}

#########
# We need plugin_enable
# as we have an external dependency
#########
sub plugin_enable {
	my $self   = shift;
	my $main   = $self->main;
	my $config = $main->config;
	my $nick   = 0;

	# Tests for externals used by Preference's
	if ( $config->identity_nickname ) {
		$nick = 1;
	}

	return $nick;
}

#######
# plugin menu
#######
sub menu_plugins {
	my $self = shift;
	my $main = $self->main;

	# Create a manual menu item
	my $menu_item = Wx::MenuItem->new( undef, -1, $self->plugin_name . "\tCtrl+Shift+V", );
	Wx::Event::EVT_MENU(
		$main,
		$menu_item,
		sub {
			$self->paste_it;
		},
	);

	return $menu_item;
}

########
# plugin_disable
########
sub plugin_disable {
	my $self = shift;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Unload all our child classes
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}

	$self->SUPER::plugin_disable(@_);

	return 1;
}

########
# Composed Method clean_dialog
########
sub clean_dialog {
	my $self = shift;

	# Close the main dialog if it is hanging around
	if ( $self->{dialog} ) {
		$self->{dialog}->Hide;
		$self->{dialog}->Destroy;
		delete $self->{dialog};
	}

	return 1;
}


#######
# plugin_preferences
#######
sub plugin_preferences {
	my $self = shift;
	my $main = $self->main;

	# Clean up any previous existing dialog
	$self->clean_dialog;

	# try {
	# require Padre::Plugin::SpellCheck::Preferences;
	# $self->{dialog} = Padre::Plugin::SpellCheck::Preferences->new($main);
	# $self->{dialog}->ShowModal;
	# }
	# catch {
	# $self->main->error( sprintf Wx::gettext('Error: %s'), $_ );
	# };

	return;
}


#######
# paste_it
#######
sub paste_it {
	my $self   = shift;
	my $main   = $self->main;
	my $config = $main->config;

	my $output   = $main->output;
	my $current  = $self->current;
	my $document = $current->document;

	my $full_text     = $document->text_get;
	my $selected_text = $current->text;

	# say 'start paste_it';

	# TRACE('start paste_it') if DEBUG;

	my $text = $selected_text || $full_text;
	return unless defined $text;

	require Padre::Plugin::Nopaste::Task;

	# # Fire the task
	$self->task_request(
		task      => 'Padre::Plugin::Nopaste::Task',
		text      => $text,
		nick      => $config->identity_nickname,
		on_finish => 'on_finish',
	);

	# say 'end paste_it';
	return;
}

#######
# on compleation of task do this
#######
sub on_finish {
	my $self = shift;
	my $task = shift;

	# say 'start on_finish';

	# TRACE("nopaste_response") if DEBUG;


	# Generate the dump string and set into the output window
	my $main = $self->main;
	$main->show_output(1);
	my $output = $main->output;
	$output->clear;
	if ( $task->{error} ) {
		$output->AppendText('Something went wrong, here is the response we got:');
	}
	$output->AppendText( $task->{message} );

	# say $task->{error};
	# say $task->{message};

	# # Found what we were looking for
	# if ( $task->{location} ) {

	# #$self->ppi_select( $task->{location} );
	# #return;
	# }

	# my $main = $self->current->main;

	# Generate the dump string and set into the output window
	# $main->output->SetValue( $task->{message} );
	# $main->output->SetSelection( 0, 0 );
	# $main->show_output(1);

	# Must have been a clean result
	# TO DO: Convert this to a call to ->main that doesn't require
	# us to use Wx directly.
	#	Wx::MessageBox(
	#		$task->{message},
	#		$task->{message},
	#		Wx::wxOK,
	#		$self->current->main,
	#	);

	# say 'start on_finish';
	return;

}


#######
# Add icon to Plugin
#######
sub plugin_icon {
	my $class = shift;
	my $share = $class->plugin_directory_share or return;
	my $file  = File::Spec->catfile( $share, 'icons', '16x16', 'nopaste.png' );
	return unless -f $file;
	return unless -r $file;
	return Wx::Bitmap->new( $file, Wx::wxBITMAP_TYPE_PNG );
}

#######
# Add Preferences to Context Menu
#######
sub event_on_context_menu {
	my ( $self, $document, $editor, $menu, $event ) = @_;

	#Test for valid file type
	return if not $document->filename;

	$menu->AppendSeparator;

	my $item = $menu->Append( -1, Wx::gettext('Nopaste Preferences...') );
	Wx::Event::EVT_MENU(
		$self->main,
		$item,
		sub { $self->plugin_preferences },
	);

	return;
}

1;
__END__


=head1 NAME

Padre::Plugin::Nopaste - send code on a nopaste website from padre



=head1 SYNOPSIS

    $ padre
    Ctrl+Shift+V



=head1 DESCRIPTION

This plugin allows one to send stuff from Padre to a nopaste website
with Ctrl+Shift+V, allowing for easy code / whatever sharing without
having to open a browser.

It is using C<App::Nopaste> underneath, so check this module's pod for
more information.


=head1 PUBLIC METHODS

=head2 Standard Padre::Plugin API

C<Padre::Plugin::Nopaste> defines a plugin which follows C<Padre::Plugin>
API. Refer to this module's documentation for more information.

The following methods are implemented:

=over 4

=item 	paste_it

runs nopaste as a padre task

=item 	on_finish

post task, display result

=item padre_interfaces()

=item plugin_icon()

=item plugin_name()

=item clean_dialog()

=item menu_plugins()

=item plugin_disable()

=item plugin_enable()

=item plugin_preferences()

Spelling preferences window normaly access via Plug-in Manager

=item event_on_context_menu

Add access to spelling preferences window.

=back



=head2 Standard Padre::Role::Task API

In order not to freeze Padre during web access, nopasting is done in a thread,
as implemented by C<Padre::Task>. Refer to this module's documentation for more
information.

The following methods are implemented:

=over 4

=item * nopaste()

=item * task_response()

Callback for task runned by nopaste().

=back



=head1 BUGS

Please report any bugs or feature requests to C<padre-plugin-nopaste at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Nopaste>. I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.



=head1 SEE ALSO

Plugin icon courtesy of Mark James, at
L<http://www.famfamfam.com/lab/icons/silk/>.

Our git repository is located at L<git://repo.or.cz/padre-plugin-nopaste.git>,
and can be browsed at L<http://repo.or.cz/w/padre-plugin-nopaste.git>.


You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Nopaste>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Nopaste>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Nopaste>

=back



=head1 AUTHOR

Jerome Quelin, C<< <jquelin@cpan.org> >>



=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
