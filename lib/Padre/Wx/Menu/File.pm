package Padre::Wx::Menu::File;

# Fully encapsulated File menu

use 5.008;
use strict;
use warnings;
use Padre::Wx       ();
use Padre::Wx::Menu ();
use Padre::Current qw{_CURRENT};

our $VERSION = '0.40';
our @ISA     = 'Padre::Wx::Menu';

#####################################################################
# Padre::Wx::Menu Methods

sub new {
	my $class = shift;
	my $main  = shift;

	# Create the empty menu as normal
	my $self = $class->SUPER::new(@_);

	# Add additional properties
	$self->{main} = $main;

	my $action;
	my $menu_item;

	# Create new things

	($self->{new}, $action) = $self->add_menu_item(
		$self,
		name       => 'file.new', 
		label      => Wx::gettext('&New'), 
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
	($menu_item, $action) = $self->add_menu_item(
		$file_new,
		name       => 'file.new_p5_script', 
		label      => Wx::gettext('Perl 5 Script'), 
		menu_event => sub {
			$_[0]->on_new_from_template('pl');
		},
	);
	($menu_item, $action) = $self->add_menu_item(
		$file_new,
		name       => 'file.new_p5_module', 
		label      => Wx::gettext('Perl 5 Module'), 
		menu_event => sub {
			$_[0]->on_new_from_template('pm');
		},
	);
	($menu_item, $action) = $self->add_menu_item(
		$file_new,
		name       => 'file.new_p5_test', 
		label      => Wx::gettext('Perl 5 Test'), 
		menu_event => sub {
			$_[0]->on_new_from_template('t');
		},
	);
	($menu_item, $action) = $self->add_menu_item(
		$file_new,
		name       => 'file.new_p6_script', 
		label      => Wx::gettext('Perl 6 Script'), 
		menu_event => sub {
			$_[0]->on_new_from_template('p6');
		},
	);
	($menu_item, $action) = $self->add_menu_item(
		$file_new,
		name       => 'file.new_p5_module', 
		label      => Wx::gettext('Perl Distribution (Module::Starter)'), 
		menu_event => sub {
			require Padre::Wx::Dialog::ModuleStart;
			Padre::Wx::Dialog::ModuleStart->start( $_[0] );
		},
	);

	# Open and close files
	($menu_item, $action) = $self->add_menu_item(
		$self,
		name       => 'file.open', 
		id         => Wx::wxID_OPEN,
		label      => Wx::gettext('&Open...'), 
		shortcut   => 'Ctrl-O',
		menu_event => sub {
			$_[0]->on_open;
		},
	);

	($self->{close}, $action) = $self->add_menu_item(
		$self,
		name       => 'file.close', 
		id         => Wx::wxID_CLOSE,
		label      => Wx::gettext('&Close...'), 
		shortcut   => 'Ctrl-W',
		menu_event => sub {
			$_[0]->on_close;
		},
	);

	($self->{close_all}, $action) = $self->add_menu_item(
		$self,
		name       => 'file.close_all', 
		label      => Wx::gettext('Close All'), 
		shortcut   => 'Ctrl-W',
		menu_event => sub {
			$_[0]->on_close_all;
		},
	);
	($self->{close_all_but_current}, $action) = $self->add_menu_item(
		$self,
		name       => 'file.close_all_but_current', 
		label      => Wx::gettext('Close All but Current'), 
		menu_event => sub {
			$_[0]->on_close_all_but_current;
		},
	);
	($self->{reload_file}, $action) = $self->add_menu_item(
		$self,
		name       => 'file.reload_file', 
		label      => Wx::gettext('Reload File'), 
		menu_event => sub {
			$_[0]->on_reload_file;
		},
	);

	$self->AppendSeparator;

	# Save files
	($self->{save}, $action) = $self->add_menu_item(
		$self,
		name       => 'file.save', 
		id         => Wx::wxID_SAVE,
		label      => Wx::gettext('&Save'), 
		shortcut   => 'Ctrl-S',
		menu_event => sub {
			$_[0]->on_save;
		},
	);
	($self->{save_as}, $action) = $self->add_menu_item(
		$self,
		name       => 'file.save_as', 
		id         => Wx::wxID_SAVEAS,
		label      => Wx::gettext('Save &As'), 
		shortcut   => 'F12',
		menu_event => sub {
			$_[0]->on_save_as;
		},
	);
	$self->{save_all} = $self->Append(
		-1,
		Wx::gettext('Save All')
	);
	Wx::Event::EVT_MENU(
		$main,
		$self->{save_all},
		sub {
			$_[0]->on_save_all;
		},
	);

	$self->AppendSeparator;

	# Specialised open and close functions
	$self->{open_selection} = $self->Append(
		-1,
		Wx::gettext("Open Selection\tCtrl-Shift-O")
	);
	Wx::Event::EVT_MENU(
		$main,
		$self->{open_selection},
		sub {
			$_[0]->on_open_selection;
		},
	);

	$self->{open_session} = $self->Append(
		-1,
		Wx::gettext("Open Session...\tCtrl-Alt-O")
	);
	Wx::Event::EVT_MENU(
		$main,
		$self->{open_session},
		sub {
			require Padre::Wx::Dialog::SessionManager;
			Padre::Wx::Dialog::SessionManager->new( $_[0] )->show;
		},
	);

	$self->{save_session} = $self->Append(
		-1,
		Wx::gettext("Save Session...\tCtrl-Alt-S")
	);
	Wx::Event::EVT_MENU(
		$main,
		$self->{save_session},
		sub {
			require Padre::Wx::Dialog::SessionSave;
			Padre::Wx::Dialog::SessionSave->new( $_[0] )->show;
		},
	);

	$self->AppendSeparator;

	# Print files
	$self->{print} = $self->Append(
		Wx::wxID_PRINT,
		Wx::gettext('&Print...'),
	);
	Wx::Event::EVT_MENU(
		$main,
		$self->{print},
		sub {
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
	Wx::Event::EVT_MENU(
		$main,
		$self->{recentfiles}->Append(
			-1,
			Wx::gettext("Open All Recent Files")
		),
		sub {
			$_[0]->on_open_all_recent_files;
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$self->{recentfiles}->Append(
			-1,
			Wx::gettext("Clean Recent Files List")
		),
		sub {
			Padre::DB::History->delete( 'where type = ?', 'files' );
			$self->update_recentfiles;
		},
	);

	$self->{recentfiles}->AppendSeparator;

	$self->update_recentfiles;

	$self->AppendSeparator;

	# Word Stats
	$self->{docstat} = $self->Append(
		-1,
		Wx::gettext('Document Statistics')
	);
	Wx::Event::EVT_MENU(
		$main,
		$self->{docstat},
		sub {
			$_[0]->on_doc_stats;
		},
	);

	$self->AppendSeparator;

	# Exiting
	Wx::Event::EVT_MENU(
		$main,
		$self->Append(
			Wx::wxID_EXIT,
			Wx::gettext("&Quit\tCtrl-Q")
		),
		sub {
			$_[0]->Close;
		},
	);

	return $self;
}

sub refresh {
	my $self    = shift;
	my $current = _CURRENT(@_);
	my $doc     = $current->document ? 1 : 0;

	$self->{close}->Enable($doc);
	$self->{close_all}->Enable($doc);
	$self->{close_all_but_current}->Enable($doc);
	$self->{reload_file}->Enable($doc);
	$self->{save}->Enable($doc);
	$self->{save_as}->Enable($doc);
	$self->{save_all}->Enable($doc);
	$self->{print}->Enable($doc);
	$self->{open_selection}->Enable($doc);
	$self->{save_session}->Enable($doc);
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
				$_[0]->setup_editors($file);
			},
		);
		Padre::Util::debug("Recent entry created for '$file'");
	}

	return;
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
