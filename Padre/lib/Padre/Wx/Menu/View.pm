package Padre::Wx::Menu::View;

# Fully encapsulated View menu

use 5.008;
use strict;
use warnings;
use Padre::Constant          ();
use Padre::Current           ();
use Padre::Feature           ();
use Padre::Wx                ();
use Padre::Wx::ActionLibrary ();
use Padre::Wx::Menu          ();
use Padre::Locale            ();

our $VERSION    = '0.92';
our $COMPATIBLE = '0.87';
our @ISA        = 'Padre::Wx::Menu';





#####################################################################
# Padre::Wx::Menu Methods

sub new {
	my $class  = shift;
	my $main   = shift;
	my $config = $main->config;

	# Create the empty menu as normal
	my $self = $class->SUPER::new(@_);

	# Add additional properties
	$self->{main} = $main;

	# Can the user move stuff around
	$self->{lockinterface} = $self->add_menu_action(
		'view.lockinterface',
	);

	$self->AppendSeparator;

	# Show or hide GUI elements
	$self->{command_line} = $self->add_menu_action(
		'view.command_line',
	);

	$self->{cpan_explorer} = $self->add_menu_action('view.cpan_explorer')
		if $main->config->feature_cpan_explorer;

	$self->{functions} = $self->add_menu_action(
		'view.functions',
	);

	$self->{directory} = $self->add_menu_action(
		'view.directory',
	);

	$self->{outline} = $self->add_menu_action(
		'view.outline',
	);

	$self->{output} = $self->add_menu_action(
		'view.output',
	);

	$self->{syntaxcheck} = $self->add_menu_action(
		'view.syntaxcheck',
	);

	$self->{todo} = $self->add_menu_action(
		'view.todo',
	);

	$self->{vcs} = $self->add_menu_action('view.vcs')
		if $main->config->feature_vcs_support;

	$self->{toolbar} = $self->add_menu_action(
		'view.toolbar',
	);

	$self->{statusbar} = $self->add_menu_action(
		'view.statusbar',
	);

	$self->AppendSeparator;

	# View as (Highlighting File Type)
	SCOPE: {
		$self->{view_as_highlighting} = Wx::Menu->new;
		$self->Append(
			-1,
			Wx::gettext("&View Document As..."),
			$self->{view_as_highlighting}
		);

		my %mimes = Padre::MimeTypes::menu_view_mimes();
		my @names = $self->sort_mimes( \%mimes );
		foreach my $name (@names) {
			my $radio = $self->add_menu_action(
				$self->{view_as_highlighting},
				"view.mime.$name",
			);
		}
	}

	$self->AppendSeparator;

	# Show or hide editor elements
	$self->{currentline} = $self->add_menu_action(
		'view.currentline',
	);

	$self->{lines} = $self->add_menu_action(
		'view.lines',
	);

	$self->{indentation_guide} = $self->add_menu_action(
		'view.indentation_guide',
	);

	$self->{whitespaces} = $self->add_menu_action(
		'view.whitespaces',
	);

	$self->{calltips} = $self->add_menu_action(
		'view.calltips',
	);

	$self->{eol} = $self->add_menu_action(
		'view.eol',
	);

	$self->{rightmargin} = $self->add_menu_action(
		'view.rightmargin',
	);

	# Code folding menu entries
	if (Padre::Feature::FOLDING) {
		$self->AppendSeparator;

		$self->{folding} = $self->add_menu_action(
			'view.folding',
		);

		$self->{fold_all} = $self->add_menu_action(
			'view.fold_all',
		);

		$self->{unfold_all} = $self->add_menu_action(
			'view.unfold_all',
		);

		$self->{fold_this} = $self->add_menu_action(
			'view.fold_this',
		);
	}

	$self->AppendSeparator;

	$self->{word_wrap} = $self->add_menu_action(
		'view.word_wrap',
	);

	$self->AppendSeparator;

	# Font Size
	if (Padre::Feature::FONTSIZE) {
		$self->{fontsize} = Wx::Menu->new;
		$self->Append(
			-1,
			Wx::gettext('Font Si&ze'),
			$self->{fontsize}
		);

		$self->{font_increase} = $self->add_menu_action(
			$self->{fontsize},
			'view.font_increase',
		);

		$self->{font_decrease} = $self->add_menu_action(
			$self->{fontsize},
			'view.font_decrease',
		);

		$self->{font_reset} = $self->add_menu_action(
			$self->{fontsize},
			'view.font_reset',
		);
	}

	# Language Support
	Padre::Wx::ActionLibrary->init_language_actions;

	# TO DO: God this is horrible, there has to be a better way
	my $default  = Padre::Locale::system_rfc4646() || 'x-unknown';
	my $current  = Padre::Locale::rfc4646();
	my %language = Padre::Locale::menu_view_languages();

	# Parent Menu
	$self->{language} = Wx::Menu->new;
	$self->Append(
		-1,
		Wx::gettext('Lan&guage'),
		$self->{language}
	);

	# Default menu entry
	$self->{language_default} = $self->add_menu_action(
		$self->{language},
		'view.language.default',
	);
	if ( defined $config->locale and $config->locale eq $default ) {
		$self->{language_default}->Check(1);
	}

	$self->{language}->AppendSeparator;

	foreach my $name ( sort { $language{$a} cmp $language{$b} } keys %language ) {
		my $radio = $self->add_menu_action(
			$self->{language},
			"view.language.$name",
		);

		if ( $current eq $name ) {
			$radio->Check(1);
		}
	}

	$self->AppendSeparator;

	# Window Effects
	$self->add_menu_action(
		'view.full_screen',
	);

	return $self;
}

sub title {
	Wx::gettext('&View');
}

sub refresh {
	my $self     = shift;
	my $current  = Padre::Current::_CURRENT(@_);
	my $config   = $current->config;
	my $document = $current->document;
	my $doc      = $document ? 1 : 0;

	# Simple check state cases from configuration
	$self->{statusbar}->Check( $config->main_statusbar );
	$self->{lines}->Check( $config->editor_linenumbers );
	$self->{currentline}->Check( $config->editor_currentline );
	$self->{rightmargin}->Check( $config->editor_right_margin_enable );
	$self->{eol}->Check( $config->editor_eol );
	$self->{whitespaces}->Check( $config->editor_whitespace );
	$self->{output}->Check( $config->main_output );
	$self->{outline}->Check( $config->main_outline );
	$self->{directory}->Check( $config->main_directory );
	$self->{functions}->Check( $config->main_functions );
	$self->{todo}->Check( $config->main_todo );
	$self->{lockinterface}->Check( $config->main_lockinterface );
	$self->{indentation_guide}->Check( $config->editor_indentationguides );
	$self->{calltips}->Check( $config->editor_calltips );
	$self->{command_line}->Check( $config->main_command_line );
	$self->{syntaxcheck}->Check( $config->main_syntaxcheck );
	$self->{vcs}->Check( $config->main_vcs ) if $config->feature_vcs_support;
	$self->{cpan_explorer}->Check( $config->main_cpan_explorer )
		if $config->feature_cpan_explorer;
	$self->{toolbar}->Check( $config->main_toolbar );

	if (Padre::Feature::FOLDING) {
		my $folding = $config->editor_folding;
		$self->{folding}->Check($folding);
		$self->{fold_all}->Enable($folding);
		$self->{unfold_all}->Enable($folding);
		$self->{fold_this}->Enable($folding);
	}

	# Check state for word wrap is document-specific
	if ($document) {
		my $editor = $document->editor;
		my $mode   = $editor->get_wrap_mode;
		my $wrap   = $self->{word_wrap};
		if ( $mode eq 'WORD' and not $wrap->IsChecked ) {
			$wrap->Check(1);
		} elsif ( $mode eq 'NONE' and $wrap->IsChecked ) {
			$wrap->Check(0);
		}

		# Set mimetype
		my $has_checked = 0;
		if ( $document->mimetype ) {
			my %mimes = Padre::MimeTypes::menu_view_mimes();
			my @mimes = $self->sort_mimes( \%mimes );
			foreach my $pos ( 0 .. scalar @mimes - 1 ) {
				my $radio = $self->{view_as_highlighting}->FindItemByPosition($pos);
				if ( $document->mimetype eq $mimes[$pos] ) {
					$radio->Check(1);
					$has_checked = 1;
				}
			}
		}

		# By default 'Plain Text';
		unless ($has_checked) {
			$self->{view_as_highlighting}->FindItemByPosition(0)->Check(1);
		}
	}

	# Disable zooming if there's no current document
	if (Padre::Feature::FONTSIZE) {
		$self->{font_increase}->Enable($doc);
		$self->{font_decrease}->Enable($doc);
		$self->{font_reset}->Enable($doc);
	}

	return;
}

sub sort_mimes {
	my $self  = shift;
	my $mimes = shift;

	# Can't do "return sort", must sort to a list first
	my @sorted = sort {
		( $b eq 'text/plain' ) <=> ( $a eq 'text/plain' )
			or Wx::gettext( $mimes->{$a} ) cmp Wx::gettext( $mimes->{$b} )
	} keys %$mimes;

	return @sorted;
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
