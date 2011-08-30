package Padre::Plugin::Patch::Main;

use 5.008;
use strict;
use warnings;
use File::Slurp                       ();
use Padre::Wx                         ();
use Padre::Plugin::Patch::FBP::MainFB ();
use Padre::Current;
use Padre::Logger;

# use Data::Printer { caller_info => 1 };
our $VERSION = '0.04';
our @ISA     = 'Padre::Plugin::Patch::FBP::MainFB';

#######
# new
#######
sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	$self->CenterOnParent;
	$self->{action_request} = 'Patch';
	$self->{selection}      = 0;
	$self->set_up;
	return $self;
}

#######
# Method set_up
#######
sub set_up {
	my $self = shift;
	my $main = $self->main;

	# generate open file bucket
	current_files($self);

	# display default saved file lists
	file_lists_saved($self);

	# display correct file-2 list
	file2_list_type($self);

	$self->against->SetSelection(0);

	return;
}

#######
# Event Handler process_clicked
#######
sub process_clicked {
	my $self = shift;

	my $file1 = @{ $self->{file1_list_ref} }[ $self->file1->GetSelection() ];
	my $file2 = @{ $self->{file2_list_ref} }[ $self->file2->GetCurrentSelection() ];

	TRACE( $self->action->GetStringSelection() ) if DEBUG;

	if ( $self->action->GetStringSelection() eq 'Patch' ) {
		$self->apply_patch( $file1, $file2 );
	}

	if ( $self->action->GetStringSelection() eq 'Diff' ) {

		if ( $self->against->GetStringSelection() eq 'File-2' ) {
			$self->make_patch_diff( $file1, $file2 );
		} elsif ( $self->against->GetStringSelection() eq 'SVN' ) {
			$self->make_patch_svn($file1);
		}
	}

	# reset dialogue's display information
	$self->set_up;

	return;
}

#######
# Event Handler on_action
#######
sub on_action {
	my $self = shift;
	if ( $self->action->GetStringSelection() eq 'Patch' ) {

		$self->{action_request} = 'Patch';
		$self->set_up;
		$self->against->Enable(0);
		$self->file2->Enable(1);
	} else {

		# Diff
		$self->{action_request} = 'Diff';
		$self->set_up;
		$self->against->Enable(1);
		$self->file2->Enable(1);

		# as we can not added items to a radio-box,
		# we can only enable & disable when radio-box enabled
		# test inspired my Any
		unless ( eval { require SVN::Class } ) {
			$self->against->EnableItem( 1, 0 );
		}
		$self->against->SetSelection(0);

	}
	return;
}

#######
# Event Handler on_against
#######
sub on_against {
	my $self = shift;

	if ( $self->against->GetStringSelection() eq 'File-2' ) {

		# show saved files only
		$self->file2->Enable(1);
		file_lists_saved($self);

	} elsif ( $self->against->GetStringSelection() eq 'SVN' ) {

		# SVN only display files that are part of a SVN
		$self->file2->Enable(0);
		file1_list_svn($self);
	}

	return;
}

#######
# Method current_files
#######
sub current_files {
	my $self     = shift;
	my $main     = $self->main;
	my $current  = $main->current;
	my $notebook = $current->notebook;
	my @label    = $notebook->labels;
	$self->{tab_cardinality} = scalar(@label) - 1;

	# thanks Alias
	my @file_vcs = map { $_->project->vcs } Padre::Current->main->documents;

	# create a bucket for open file info, as only a current file bucket exist
	for ( 0 .. $self->{tab_cardinality} ) {
		$self->{open_file_info}->{$_} = (
			{   'index'    => $_,
				'URL'      => $label[$_][1],
				'filename' => $notebook->GetPageText($_),
				'changed'  => 0,
				'vcs'      => $file_vcs[$_],
			},
		);

		if ( $notebook->GetPageText($_) =~ /^\*/sxm ) {
			TRACE("Found an unsaved file, will ignore: $notebook->GetPageText($_)") if DEBUG;
			$self->{open_file_info}->{$_}->{'changed'} = 1;
		}
	}

	# nb enable Data::Printer above to use
	# p $self->{open_file_info};

	return;
}

#######
# Composed Method file2_list_type
#######
sub file2_list_type {
	my $self = shift;

	if ( $self->{action_request} eq 'Patch' ) {

		# update File-2 = *.patch
		file2_list_patch($self);
	} else {

		# File-1 = File-2 = saved files
		file_lists_saved($self);
	}

	return;
}

#######
# Composed Method file_lists_saved
#######
sub file_lists_saved {
	my $self = shift;
	my @file_lists_saved;
	for ( 0 .. $self->{tab_cardinality} ) {
		unless ( $self->{open_file_info}->{$_}->{'changed'}
			|| $self->{open_file_info}->{$_}->{'filename'} =~ /(patch|diff)$/sxm )
		{
			push @file_lists_saved, $self->{open_file_info}->{$_}->{'filename'};
		}
	}

	TRACE("file_lists_saved: @file_lists_saved") if DEBUG;

	$self->file1->Clear;
	$self->file1->Append( \@file_lists_saved );
	$self->{file1_list_ref} = \@file_lists_saved;
	set_selection($self);
	$self->file1->SetSelection( $self->{selection} );

	$self->file2->Clear;
	$self->file2->Append( \@file_lists_saved );
	$self->file2->SetSelection( $self->{selection} );
	$self->{file2_list_ref} = \@file_lists_saved;

	return;
}

#######
# Composed Method file2_list_patch
#######
sub file2_list_patch {
	my $self = shift;
	my @file2_list_patch;
	for ( 0 .. $self->{tab_cardinality} ) {
		if ( $self->{open_file_info}->{$_}->{'filename'} =~ /(patch|diff)$/sxm ) {
			push @file2_list_patch, $self->{open_file_info}->{$_}->{'filename'};
		}
	}

	TRACE("file2_list_patch: @file2_list_patch") if DEBUG;

	$self->file2->Clear;
	$self->file2->Append( \@file2_list_patch );
	$self->file2->SetSelection(0);
	$self->{file2_list_ref} = \@file2_list_patch;

	return;
}

#######
# Composed Method file1_list_svn
#######
sub file1_list_svn {
	my $self = shift;
	my @file1_list_svn;

	for ( 0 .. $self->{tab_cardinality} ) {
		if (   ( $self->{open_file_info}->{$_}->{'vcs'} eq 'SVN' )
			&& !( $self->{open_file_info}->{$_}->{'changed'} )
			&& !( $self->{open_file_info}->{$_}->{'filename'} =~ /(patch|diff)$/sxm ) )
		{
			push @file1_list_svn, $self->{open_file_info}->{$_}->{'filename'};
		}
	}

	TRACE("file1_list_svn: @file1_list_svn") if DEBUG;

	$self->file1->Clear;
	$self->file1->Append( \@file1_list_svn );
	$self->{file1_list_ref} = \@file1_list_svn;
	set_selection($self);
	$self->file1->SetSelection( $self->{selection} );

	return;
}

#######
# Composed Method set_selection
#######
sub set_selection {
	my $self = shift;
	my $main = $self->main;

	# SetSelection should be current file
	foreach ( 0 .. @{ $self->{file1_list_ref} } - 1 ) {

		if ( @{ $self->{file1_list_ref} }[$_] eq $main->current->title ) {
			$self->{selection} = $_;
		}
	}
	return;
}

#######
# Composed Method filename_url
#######
sub filename_url {
	my $self     = shift;
	my $filename = shift;

	# given tab name get url of file
	for ( 0 .. $self->{tab_cardinality} ) {
		if ( $self->{open_file_info}->{$_}->{'filename'} eq $filename ) {
			return $self->{open_file_info}->{$_}->{'URL'};
		}
	}
	return;
}

########
# Method apply_patch
########
sub apply_patch {
	my $self       = shift;
	my $file1_name = shift;
	my $file2_name = shift;
	my $main       = $self->main;

	my ( $source, $diff );

	my $file1_url = filename_url( $self, $file1_name );
	my $file2_url = filename_url( $self, $file2_name );

	if ( -e $file1_url ) {
		TRACE("found $file1_url: $file1_url") if DEBUG;
		$source = File::Slurp::read_file($file1_url);
	}

	if ( -e $file2_url ) {
		TRACE("found $file2_url: $file2_url") if DEBUG;
		$diff = File::Slurp::read_file($file2_url);
		unless ( $file2_url =~ /(patch|diff)$/sxm ) {
			$main->info( Wx::gettext('Patch file should end in .patch or .diff, you should reselect & try again') );
			return;
		}
	}

	if ( -e $file1_url && -e $file2_url ) {

		require Text::Patch;
		my $our_patch;
		eval { $our_patch = Text::Patch::patch( $source, $diff, { STYLE => 'Unified' } ); };
		TRACE($our_patch) if DEBUG;

		# Open the patched file as a new file
		$main->new_document_from_string( $our_patch => 'application/x-perl', );
		$main->info( Wx::gettext('Patch Succesful, you should see a new tab in editor called Unsaved #') );
	} else {
		$main->info( Wx::gettext('Sorry Patch Failed, are you sure your choice of files was correct for this action') );
	}

	return;
}

#######
# Method make_patch_diff
#######
sub make_patch_diff {
	my $self       = shift;
	my $file1_name = shift;
	my $file2_name = shift;
	my $main       = $self->main;

	my $file1_url = filename_url( $self, $file1_name );
	my $file2_url = filename_url( $self, $file2_name );

	if ( -e $file1_url ) {
		TRACE("found $file1_url: $file1_url") if DEBUG;
	}

	if ( -e $file2_url ) {
		TRACE("found $file2_url: $file2_url") if DEBUG;
	}

	if ( -e $file1_url && -e $file2_url ) {
		require Text::Diff;
		my $our_diff;
		eval { $our_diff = Text::Diff::diff( $file1_url, $file2_url, { STYLE => 'Unified' } ); };
		TRACE($our_diff) if DEBUG;

		my $patch_file = $file1_url . '.patch';

		File::Slurp::write_file( $patch_file, $our_diff );
		TRACE("writing file: $patch_file") if DEBUG;

		$main->setup_editor($patch_file);
		$main->info( Wx::gettext("Diff Succesful, you should see a new tab in editor called $patch_file") );
	} else {
		$main->info( Wx::gettext('Sorry Diff Failed, are you sure your choice of files was correct for this action') );
	}

	return;
}

#######
# Method make_patch_svn
# inspired by P-P-SVN
#######
sub make_patch_svn {
	my $self       = shift;
	my $file1_name = shift;
	my $main       = $self->main;

	my $file1_url = filename_url( $self, $file1_name );

	TRACE("file1_url to svn: $file1_url") if DEBUG;

	if ( eval { require SVN::Class } ) {
		TRACE('found SVN::Class, Good to go') if DEBUG;

		my $file = SVN::Class::svn_file($file1_url);
		$file->diff;

		# TODO talk to Alias about supporting Data::Printer { caller_info => 1 }; in Padre::Logger
		# TRACE output is yuck
		TRACE( @{ $file->stdout } ) if DEBUG;
		my $diff_str = join "\n", @{ $file->stdout };

		TRACE($diff_str) if DEBUG;

		my $patch_file = $file1_url . '.patch';

		File::Slurp::write_file( $patch_file, $diff_str );
		TRACE("writing file: $patch_file") if DEBUG;

		$main->setup_editor($patch_file);
		$main->info( Wx::gettext("SVN Diff Succesful, you should see a new tab in editor called $patch_file") );
	}

	return;
}

1;

__END__

=head1 NAME

Padre::Plugin::Patch::Main

=head1 VERSION

This document describes Padre::Plugin::Patch::Main version 0.03

=head1 DESCRIPTION

A very simplistic tool, only works on open saved files, in the Padre editor.

Patch a single file, in the editor with a patch/diff file that is also open.

Diff between two open files, the resulting patch file will be in Unified form.

Diff a single file to svn, only display files that are part of an SVN already, the resulting patch file will be in Unified form.

All results will be a new Tab.

=head1 METHODS

=over 4

=item new

Constructor. Should be called with C<$main> by C<Patch::load_dialog_main()>.

=item set_up

C<set_up> configures the dialogue for your environment

=item on_action

Event handler for action, adjust dialogue accordingly

=item on_against

Event handler for against, adjust dialogue accordingly

=item process_clicked

Event handler for process_clicked, perform your chosen action, all results go into a new tab in editor.

=item current_files

extracts file info from Padre about all open files in editor

=item apply_patch

A convenience method to apply patch to chosen file.

=item make_patch_diff

A convenience method to generate a patch/diff file from two selected files.

=item make_patch_svn

NB only works if you have C<SVN::Class> installed.

A convenience method to generate a patch/diff file from a selected file and svn if applicable,
ie file has been checked out.

=item file2_list_type

composed method

=item filename_url

composed method

=item set_selection

composed method

=item file1_list_svn

composed method

=item file2_list_patch

composed method

=item file_lists_saved

composed method

=back

=head1 BUGS AND LIMITATIONS 

List Order is that of load order, if you move your Tabs the List Order will not follow suite.


=head1 AUTHORS

BOWTIE E<lt>kevin.dawson@btclick.comE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2008-2011 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl 5 itself.

The full text of the license can be found in the
LICENSE file included with this module.

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
