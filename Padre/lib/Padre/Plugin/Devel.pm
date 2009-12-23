package Padre::Plugin::Devel;

use 5.008;
use strict;
use warnings;
use Padre::Wx      ();
use Padre::Plugin  ();
use Padre::Current ();

our $VERSION = '0.53';
our @ISA     = 'Padre::Plugin';





#####################################################################
# Padre::Plugin Methods

sub padre_interfaces {
	( 'Padre::Plugin' => 0.43, 'Padre::Wx::Main' => 0.43 );
}

sub plugin_name {
	Wx::gettext('Padre Developer Tools');
}

sub plugin_enable {
	my $self = shift;

	# Load our non-core dependencies
	require Devel::Dumpvar;

	# Load our configuration
	# (Used for testing purposes)
	$self->{config} = $self->config_read;

	return 1;
}

sub plugin_disable {
	my $self = shift;

	# Save our configuration
	# (Used for testing purposes)
	if ( $self->{config} ) {
		$self->{config}->{foo}++;
		$self->config_write( delete( $self->{config} ) );
	} else {
		$self->config_write( { foo => 1 } );
	}

	return 1;
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('Run Document inside Padre')  => 'eval_document',
		Wx::gettext('Run Selection inside Padre') => 'eval_selection',

		'---' => undef,

		Wx::gettext('Dump Expression')       => 'dump_expression',
		Wx::gettext('Dump Current Document') => 'dump_document',
		Wx::gettext('Dump Top IDE Object')   => 'dump_padre',
		Wx::gettext('Dump Current PPI Tree') => 'dump_ppi',
		Wx::gettext('Dump %INC and @INC')    => 'dump_inc',

		'---' => undef,

		Wx::gettext('Load All Padre Modules')    => 'load_everything',
		Wx::gettext('Simulate Crash')            => 'simulate_crash',
		Wx::gettext('Simulate Crashing Bg Task') => 'simulate_task_crash',

		'---' => undef,

		sprintf( Wx::gettext('wxWidgets %s Reference'), '2.8.10' ) => sub {
			Padre::Wx::launch_browser('http://docs.wxwidgets.org/2.8.10/');
		},
		Wx::gettext('STC Reference') => sub {
			Padre::Wx::launch_browser('http://www.yellowbrain.com/stc/index.html');
		},
		Wx::gettext('wxPerl Live Support') => sub {
			Padre::Wx::launch_irc('wxperl');
		},

		'---' => undef,

		Wx::gettext('About') => 'show_about',
	];
}





#####################################################################
# Plugin Methods

sub dump_expression {
	my $self = shift;

	# Get the expression
	require Padre::Wx::History::TextEntryDialog;
	my $dialog = Padre::Wx::History::TextEntryDialog->new(
		$self->main,
		Wx::gettext("Expression"),
		Wx::gettext("Expression"),
		'Padre::Plugin::Devel.expression',
	);
	return if $dialog->ShowModal == Wx::wxID_CANCEL;
	my $perl = $dialog->GetValue;
	$dialog->Destroy;

	# Evaluate it
	return $self->_dump_eval($perl);
}

sub eval_document {
	my $self = shift;
	my $document = $self->current->document or return;
	return $self->_dump_eval( $document->text_get );
}

sub eval_selection {
	my $self = shift;
	my $document = $self->current->document or return;
	return $self->_dump_eval( $self->current->text );
}


sub dump_document {
	my $self     = shift;
	my $current  = $self->current;
	my $document = $current->document;
	unless ($document) {
		$current->main->error( Wx::gettext('No file is open') );
		return;
	}
	return $self->_dump($document);
}

#
# Dumps the current Perl 5 PPI document to the current output window
#
sub dump_ppi {
	my $self     = shift;
	my $current  = $self->current;
	my $document = $current->document;
	my $main     = $self->current->main;

	# Make sure that there is a Perl 5 document
	require Params::Util;
	unless ( Params::Util::_INSTANCE( $current->document, 'Padre::Document::Perl' ) ) {
		$main->error( Wx::gettext('No Perl 5 file is open') );
		return;
	}

	# Generate the PPI dump string and set into the output window
	require PPI::Dumper;
	require PPI::Document;
	my $source = $document->text_get;
	my $doc    = PPI::Document->new( \$source );
	my $dumper = PPI::Dumper->new( $doc, locations => 1, indent => 4 );

	$main->output->SetValue( $dumper->string );
	$main->output->SetSelection( 0, 0 );
	$main->show_output(1);
}

sub dump_padre {
	my $self = shift;
	return $self->_dump( $self->current->ide );
}

sub dump_inc {
	$_[0]->_dump( \%INC, \@INC );
}

sub simulate_crash {
	require POSIX;
	POSIX::_exit();
}

sub simulate_task_crash {
	require Padre::Task::Debug::Crashing;
	Padre::Task::Debug::Crashing->new->schedule;
}

sub show_about {
	my $self  = shift;
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName('Padre::Plugin::Devel');
	$about->SetDescription( Wx::gettext("A set of unrelated tools used by the Padre developers\n") );
	Wx::AboutBox($about);
	return;
}

sub load_everything {
	my $self = shift;
	my $main = $self->current->main;

	# Find the location of Padre.pm
	my $padre = $INC{'Padre.pm'};
	my $parent = substr( $padre, 0, length($padre) - 3 );

	# Find everything under Padre:: with a matching version
	require File::Find::Rule;
	require ExtUtils::MakeMaker;
	my @children = grep { not $INC{$_} }
		map {"Padre/$_->[0]"}
		grep { defined( $_->[1] ) and $_->[1] eq $VERSION }
		map { [ $_, ExtUtils::MM_Unix->parse_version( File::Spec->catfile( $parent, $_ ) ) ] }
		File::Find::Rule->name('*.pm')->file->relative->in($parent);
	$main->message( "Found " . scalar(@children) . " unloaded modules" );
	return unless @children;

	# Load all of them (ignoring errors)
	my $loaded = 0;
	foreach my $child (@children) {
		eval { require $child; };
		next if $@;
		$loaded++;
	}

	# Say how many classes we loaded
	$main->message("Loaded $loaded modules");
}

# Takes a string, which it evals and then dumps to Output
sub _dump_eval {
	my $self = shift;
	my $code = shift;

	# Evecute the code and handle errors
	my @rv = eval $code;
	if ($@) {
		$self->current->main->error( sprintf( Wx::gettext("Error: %s"), $@ ) );
		return;
	}

	return $self->_dump(@rv);
}

sub _dump {
	my $self = shift;
	my $main = $self->current->main;

	# Generate the dump string and set into the output window
	$main->output->SetValue( Devel::Dumpvar->new( to => 'return' )->dump(@_) );
	$main->output->SetSelection( 0, 0 );
	$main->show_output(1);

	return;
}

1;

=pod

=head1 NAME

Padre::Plugin::Devel - tools used by the Padre developers

=head1 DESCRIPTION

=head2 Run Document inside Padre

Executes and evaluates the contents of the current (saved or unsaved)
document within the current Padre process, and then dumps the result
of the evaluation to Output.

=head2 Dump Current Document

=head2 Dump Top IDE Object

=head2 Dump %INC and @INC

Dumps the %INC hash to Output

=head2 Enable/Disable logging

=head2 Enable/Disable trace when logging

=head2 Simulate crash

=head2 wxWidgets 2.8.10 Reference

=head2 C<STC> reference

Documentation for C<wxStyledTextCtrl>, a control that wraps the Scintilla editor component.

=head2 C<wxPerl> Live Support

Connects to C<#wxperl> on C<irc.perl.org>, where people can answer queries on wxPerl problems/usage.

=head2 About

=head1 AUTHOR

Gábor Szabó

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
