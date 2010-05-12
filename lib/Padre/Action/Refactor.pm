package Padre::Action::Refactor;

# Actions for refactoring

=pod

=head1 NAME

Padre::Action::Refactor is a outsourced module. It creates Actions for
various helper functions for refactoring.

=cut

use 5.008;
use strict;
use warnings;
use List::Util    ();
use File::Spec    ();
use File::HomeDir ();
use Params::Util qw{_INSTANCE};
use Padre::Action   ();
use Padre::Wx       ();
use Padre::Wx::Menu ();
use Padre::Locale   ();
use Padre::Current qw{_CURRENT};

our $VERSION = '0.61';

#####################################################################
# Methods

sub new {
	my $class = shift;
	my $main  = shift;

	# Create the empty object as normal, it won't be used usually
	my $self = bless {}, $class;

	# Add additional properties
	$self->{main} = $main;

	# Cache the configuration
	$self->{config} = Padre->ide->config;

	# Perl-Specific Refactoring
	Padre::Action->new(
		name        => 'refactor.rename_variable',
		need_editor => 1,
		label       => Wx::gettext('Rename Variable...'),
		comment => Wx::gettext('Prompt for a replacement variable name and replace all occurrences of this variable'),
		menu_event => sub {
			my $doc = $_[0]->current->document or return;
			return unless $doc->can('lexical_variable_replacement');
			require Padre::Wx::History::TextEntryDialog;
			my $dialog = Padre::Wx::History::TextEntryDialog->new(
				$_[0],
				Wx::gettext('New name'),
				Wx::gettext('Rename variable'),
				'$foo',
			);
			return if $dialog->ShowModal == Wx::wxID_CANCEL;
			my $replacement = $dialog->GetValue;
			$dialog->Destroy;
			return unless defined $replacement;
			$doc->lexical_variable_replacement($replacement);
		},
	);

	Padre::Action->new(
		name        => 'refactor.extract_subroutine',
		need_editor => 1,
		label       => Wx::gettext('Extract Subroutine...'),
		comment     => Wx::gettext(
			      'Cut the current selection and create a new sub from it. '
				. 'A call to this sub is added in the place where the selection was.'
		),
		menu_event => sub {
			my $doc = $_[0]->current->document or return;
			return unless $doc->can('extract_subroutine');

			#my $editor = $doc->editor;
			#my $code   = $editor->GetSelectedText();
			require Padre::Wx::History::TextEntryDialog;
			my $dialog = Padre::Wx::History::TextEntryDialog->new(
				$_[0],
				Wx::gettext('Name for the new subroutine'),
				Wx::gettext('Extract Subroutine'),
				'$foo',
			);
			return if $dialog->ShowModal == Wx::wxID_CANCEL;
			my $newname = $dialog->GetValue;
			$dialog->Destroy;
			return unless defined $newname;
			$doc->extract_subroutine($newname);

		},
	);

	Padre::Action->new(
		name        => 'refactor.introduce_temporary',
		need_editor => 1,
		label       => Wx::gettext('Introduce Temporary Variable...'),
		comment     => Wx::gettext('Assign the selected expression to a newly declared variable'),
		menu_event  => sub {
			my $doc = $_[0]->current->document or return;
			return unless $doc->can('introduce_temporary_variable');
			require Padre::Wx::History::TextEntryDialog;
			my $dialog = Padre::Wx::History::TextEntryDialog->new(
				$_[0],
				Wx::gettext('Variable Name'),
				Wx::gettext('Introduce Temporary Variable'),
				'$tmp',
			);
			return if $dialog->ShowModal == Wx::wxID_CANCEL;
			my $replacement = $dialog->GetValue;
			$dialog->Destroy;
			return unless defined $replacement;
			$doc->introduce_temporary_variable($replacement);
		},
	);


	return $self;
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
