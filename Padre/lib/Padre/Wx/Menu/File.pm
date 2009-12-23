package Padre::Wx::Menu::File;

# Fully encapsulated File menu

use 5.008;
use strict;
use warnings;
use Padre::Wx       ();
use Padre::Wx::Menu ();
use Padre::Current  ('_CURRENT');
use Padre::Logger;

our $VERSION = '0.53';
our @ISA     = 'Padre::Wx::Menu';

#####################################################################
# Padre::Wx::Menu Methods

sub new {

	# TO DO: Convert this to Padre::Action::File

	my $class = shift;
	my $main  = shift;

	my $config = Padre->ide->config;

	# Create the empty menu as normal
	my $self = $class->SUPER::new(@_);

	# Add additional properties
	$self->{main} = $main;

	# Create new things

	$self->{new} = $self->add_menu_item(
		$self,
		name       => 'file.new',
		label      => Wx::gettext('&New'),
		comment    => Wx::gettext('Open a new empty document'),
		shortcut   => 'Ctrl-N',
		menu_event => sub {
			$_[0]->on_new;
		},
	);

	my $file_new = Wx::Menu->new;
	$self->Append(
		-1,
		Wx::gettext("New..."),
		$file_new,
	);
	$self->add_menu_item(
		$file_new,
		name       => 'file.new_p5_script',
		label      => Wx::gettext('Perl 5 Script'),
		comment    => Wx::gettext('Open a document with a skeleton Perl 5 script'),
		menu_event => sub {
			$_[0]->on_new_from_template('pl');
		},
	);
	$self->add_menu_item(
		$file_new,
		name       => 'file.new_p5_module',
		label      => Wx::gettext('Perl 5 Module'),
		comment    => Wx::gettext('Open a document with a skeleton Perl 5 module'),
		menu_event => sub {
			$_[0]->on_new_from_template('pm');
		},
	);
	$self->add_menu_item(
		$file_new,
		name       => 'file.new_p5_test',
		label      => Wx::gettext('Perl 5 Test'),
		comment    => Wx::gettext('Open a document with a skeleton Perl 5 test  script'),
		menu_event => sub {
			$_[0]->on_new_from_template('t');
		},
	);

	# Split by language
	$file_new->AppendSeparator;

	$self->add_menu_item(
		$file_new,
		name       => 'file.new_p6_script',
		label      => Wx::gettext('Perl 6 Script'),
		comment    => Wx::gettext('Open a document with a skeleton Perl 6 script'),
		menu_event => sub {
			$_[0]->on_new_from_template('p6');
		},
	);

	# Split projects from files
	$file_new->AppendSeparator;

	$self->add_menu_item(
		$file_new,
		name       => 'file.new_p5_distro',
		label      => Wx::gettext('Perl Distribution (Module::Starter)'),
		comment    => Wx::gettext('Setup a skeleton Perl distribution using Module::Starter'),
		menu_event => sub {
			require Padre::Wx::Dialog::ModuleStart;
			Padre::Wx::Dialog::ModuleStart->start( $_[0] );
		},
	);

	### NOTE: Add support for plugins here

	# Open things

	$self->add_menu_item(
		$self,
		name       => 'file.open',
		id         => Wx::wxID_OPEN,
		label      => Wx::gettext('&Open...'),
		comment    => Wx::gettext('Browse directory of the current document to open a file'),
		shortcut   => 'Ctrl-O',
		menu_event => sub {
			$_[0]->on_open;
		},
	);

	$self->add_menu_item(
		$self,
		name    => 'file.openurl',
		label   => Wx::gettext('Open &URL...'),
		comment => Wx::gettext('Open a file from a remote location'),

		# Is shown as Ctrl-O and I don't know why
		# shortcut => 'Ctrl-Shift-O',
		menu_event => sub {
			$_[0]->on_open_url;
		},
	);

	$self->{open_example} = $self->add_menu_item(
		$self,
		name       => 'file.open_example',
		label      => Wx::gettext('Open Example'),
		comment    => Wx::gettext('Browse the directory of the installed examples to open one file'),
		menu_event => sub {
			$_[0]->on_open_example;
		},
	);

	$self->{close} = $self->add_menu_item(
		$self,
		name        => 'file.close',
		id          => Wx::wxID_CLOSE,
		need_editor => 1,
		label       => Wx::gettext('&Close'),
		comment     => Wx::gettext('Close current document'),
		shortcut    => 'Ctrl-W',
		menu_event  => sub {
			$_[0]->on_close;
		},
	);

	# Close things

	my $file_close = Wx::Menu->new;
	$self->Append(
		-1,
		Wx::gettext("Close..."),
		$file_close,
	);

	$self->{close_current_project} = $self->add_menu_item(
		$file_close,
		name        => 'file.close_current_project',
		need_editor => 1,
		label       => Wx::gettext('Close This Project'),
		comment     => Wx::gettext('Close all the files belonging to the current project'),
		menu_event  => sub {
			my $doc = $_[0]->current->document;
			return if not $doc;
			my $dir = $doc->project_dir;
			unless ( defined $dir ) {
				$_[0]->error( Wx::gettext("File is not in a project") );
			}
			$_[0]->close_where(
				sub {
					defined $_[0]->project_dir
						and $_[0]->project_dir eq $dir;
				}
			);
		},
	);

	$self->{close_other_projects} = $self->add_menu_item(
		$file_close,
		name        => 'file.close_other_projects',
		need_editor => 1,
		label       => Wx::gettext('Close Other Projects'),
		comment     => Wx::gettext('Close all the files that do not belong to the current project'),
		menu_event  => sub {
			my $doc = $_[0]->current->document;
			return if not $doc;
			my $dir = $doc->project_dir;
			unless ( defined $dir ) {
				$_[0]->error( Wx::gettext("File is not in a project") );
			}
			$_[0]->close_where(
				sub {
					$_[0]->project_dir
						and $_[0]->project_dir ne $dir;
				}
			);
		},
	);

	$file_close->AppendSeparator;

	$self->{close_all} = $self->add_menu_item(
		$file_close,
		name        => 'file.close_all',
		need_editor => 1,
		label       => Wx::gettext('Close All Files'),
		comment     => Wx::gettext('Close all the files open in the editor'),
		menu_event  => sub {
			$_[0]->close_all;
		},
	);

	$self->{close_all_but_current} = $self->add_menu_item(
		$file_close,
		name        => 'file.close_all_but_current',
		need_editor => 1,
		label       => Wx::gettext('Close All Other Files'),
		comment     => Wx::gettext('Close all the files except the current one'),
		menu_event  => sub {
			$_[0]->close_all( $_[0]->notebook->GetSelection );
		},
	);

	$self->{reload_file} = $self->add_menu_item(
		$self,
		name        => 'file.reload_file',
		need_editor => 1,
		label       => Wx::gettext('Reload File'),
		comment     => Wx::gettext('Reload current file from disk'),
		menu_event  => sub {
			$_[0]->on_reload_file;
		},
	);

	$self->{reload_all} = $self->add_menu_item(
		$self,
		name        => 'file.reload_all',
		need_editor => 1,
		label       => Wx::gettext('Reload all files'),
		comment     => Wx::gettext('Reload all files currently open'),
		menu_event  => sub {
			$_[0]->on_reload_all;
		},
	);

	$self->AppendSeparator;

	# Save files
	$self->{save} = $self->add_menu_item(
		$self,
		name          => 'file.save',
		id            => Wx::wxID_SAVE,
		need_editor   => 1,
		need_modified => 1,
		label         => Wx::gettext('&Save'),
		comment       => Wx::gettext('Save current document'),
		shortcut      => 'Ctrl-S',
		menu_event    => sub {
			$_[0]->on_save;
		},
	);

	$self->{save_as} = $self->add_menu_item(
		$self,
		name        => 'file.save_as',
		id          => Wx::wxID_SAVEAS,
		need_editor => 1,
		label       => Wx::gettext('Save &As'),
		comment     => Wx::gettext('Allow the selection of another name to save the current document'),
		shortcut    => 'F12',
		menu_event  => sub {
			$_[0]->on_save_as;
		},
	);

	$self->{save_as} = $self->add_menu_item(
		$self,
		name        => 'file.save_intuition',
		id          => -1,
		need_editor => 1,
		label       => Wx::gettext('Save Intuition'),
		comment =>
			Wx::gettext('For new document try to guess the filename based on the file content and offer to save it.'),
		shortcut   => 'Ctrl-Shift-S',
		menu_event => sub {
			$_[0]->on_save_intuition;
		},
	);

	$self->{save_all} = $self->add_menu_item(
		$self,
		name        => 'file.save_all',
		need_editor => 1,
		label       => Wx::gettext('Save All'),
		comment     => Wx::gettext('Save all the files'),
		menu_event  => sub {
			$_[0]->on_save_all;
		},
	);

	if ( $config->func_session ) {

		$self->AppendSeparator;

		# Specialised open and close functions
		$self->{open_selection} = $self->add_menu_item(
			$self,
			name    => 'file.open_selection',
			label   => Wx::gettext('Open Selection'),
			comment => Wx::gettext('List the files that match the current selection and let the user pick one to open'),
			shortcut   => 'Ctrl-Shift-O',
			menu_event => sub {
				$_[0]->on_open_selection;
			},
		);

		$self->{open_session} = $self->add_menu_item(
			$self,
			name    => 'file.open_session',
			label   => Wx::gettext('Open Session'),
			comment => Wx::gettext(
				'Select a session. Close all the files currently open and open all the listed in the session'),
			shortcut   => 'Ctrl-Alt-O',
			menu_event => sub {
				require Padre::Wx::Dialog::SessionManager;
				Padre::Wx::Dialog::SessionManager->new( $_[0] )->show;
			},
		);

		$self->{save_session} = $self->add_menu_item(
			$self,
			name       => 'file.save_session',
			label      => Wx::gettext('Save Session'),
			comment    => Wx::gettext('Ask for a session name and save the list of files currently opened'),
			shortcut   => 'Ctrl-Alt-S',
			menu_event => sub {
				require Padre::Wx::Dialog::SessionSave;
				Padre::Wx::Dialog::SessionSave->new( $_[0] )->show;
			},
		);

	}

	$self->AppendSeparator;

	# Print files
	$self->{print} = $self->add_menu_item(
		$self,
		name => 'file.print',

		# TO DO: As long as the ID is here, the shortcut won't work on Ubuntu.
		id         => Wx::wxID_PRINT,
		label      => Wx::gettext('&Print'),
		comment    => Wx::gettext('Print the current document'),
		shortcut   => 'Ctrl-P',
		menu_event => sub {
			require Wx::Print;
			require Padre::Wx::Printout;
			my $printer  = Wx::Printer->new;
			my $printout = Padre::Wx::Printout->new(
				$_[0]->current->editor, "Print",
			);
			$printer->Print( $_[0], $printout, 1 );
			$printout->Destroy;
			return;
		},
	);

	$self->AppendSeparator;

	# Recent things
	$self->{recentfiles} = Wx::Menu->new;
	$self->Append(
		-1,
		Wx::gettext("&Recent Files"),
		$self->{recentfiles}
	);
	$self->add_menu_item(
		$self->{recentfiles},
		name       => 'file.open_recent_files',
		label      => Wx::gettext('Open All Recent Files'),
		comment    => Wx::gettext('Open all the files listed in the recent files list'),
		menu_event => sub {
			$_[0]->on_open_all_recent_files;
		},
	);
	$self->add_menu_item(
		$self->{recentfiles},
		name       => 'file.clean_recent_files',
		label      => Wx::gettext('Clean Recent Files List'),
		comment    => Wx::gettext('Remove the entries from the recent files list'),
		menu_event => sub {
			Padre::DB::History->delete( 'where type = ?', 'files' );
			$self->update_recentfiles;
		},
	);

	$self->{recentfiles}->AppendSeparator;

	$self->update_recentfiles;

	$self->AppendSeparator;

	# Word Stats
	$self->{docstat} = $self->add_menu_item(
		$self,
		name       => 'file.doc_stat',
		label      => Wx::gettext('Document Statistics'),
		comment    => Wx::gettext('Word count and other statistics of the current document'),
		menu_event => sub {
			$_[0]->on_doc_stats;
		},
	);

	$self->AppendSeparator;

	# Exiting
	$self->add_menu_item(
		$self,
		name       => 'file.quit',
		label      => Wx::gettext('&Quit'),
		comment    => Wx::gettext('Ask if unsaved files should be saved and then exit Padre'),
		shortcut   => 'Ctrl-Q',
		menu_event => sub {
			$_[0]->Close;
		},
	);

	return $self;
}

sub title {
	my $self = shift;

	return Wx::gettext('&File');
}



sub refresh {
	my $self    = shift;
	my $current = _CURRENT(@_);
	my $doc     = $current->document ? 1 : 0;

	$self->{close}->Enable($doc);
	$self->{close_all}->Enable($doc);
	$self->{close_all_but_current}->Enable($doc);
	$self->{reload_file}->Enable($doc);
	$self->{reload_all}->Enable($doc);
	$self->{save}->Enable($doc);
	$self->{save_as}->Enable($doc);
	$self->{save_all}->Enable($doc);
	$self->{print}->Enable($doc);
	defined( $self->{open_session} ) and $self->{open_selection}->Enable($doc);
	defined( $self->{save_session} ) and $self->{save_session}->Enable($doc);
	$self->{docstat}->Enable($doc);

	return 1;
}

sub update_recentfiles {
	my $self = shift;

	# menu entry count starts at 0
	# first 3 entries are "open all", "clean list" and a separator
	foreach ( my $i = $self->{recentfiles}->GetMenuItemCount - 1; $i >= 3; $i-- ) {
		if ( my $item = $self->{recentfiles}->FindItemByPosition($i) ) {
			$self->{recentfiles}->Delete($item);
		}
	}

	my $idx = 0;
	foreach my $file ( grep { -f if $_ } Padre::DB::History->recent('files') ) {
		Wx::Event::EVT_MENU(
			$self->{main},
			$self->{recentfiles}->Append(
				-1,
				++$idx < 10 ? "&$idx. $file" : "$idx. $file"
			),
			sub {
				if ( -f $file ) {
					$_[0]->setup_editors($file);
				} else {

					# Handle "File not found" situation
					Padre::DB::History->delete( 'where name = ? and type = ?', $file, 'files' );
					$self->update_recentfiles;
					Wx::MessageBox(
						sprintf( Wx::gettext("File %s not found."), $file ),
						Wx::gettext("Open cancelled"),
						Wx::wxOK,
						$self->{main},
					);
				}
			},
		);
		TRACE("Recent entry created for '$file'") if DEBUG;
	}

	return;
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
