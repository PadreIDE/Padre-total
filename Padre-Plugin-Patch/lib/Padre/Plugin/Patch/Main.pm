package Padre::Plugin::Patch::Main;

use 5.010;
use strict;
use warnings;
use File::Slurp                       ();
use Padre::Wx                         ();
use Padre::Plugin::Patch::FBP::MainFB ();
use Padre::Logger;

our $VERSION = '0.03';
our @ISA     = 'Padre::Plugin::Patch::FBP::MainFB';

#######
# new
#######
sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	$self->CenterOnParent;
	$self->{action_request} = 'Patch';
	$self->set_up;
	return $self;
}

#######
# Method set_up
#######
sub set_up {
	my $self = shift;
	my $main = $self->main;
	
	my @file1_list = $self->current_files('saved');

	# SetSelection should be current file
	my $current_tab_title = $main->current->title;

	# SetSelection should be current file
	my $selection;
	for ( 0 .. $self->{tab_cardinality} ) {
		# TODO sort out error
		if ( $file1_list[$_] eq $current_tab_title ) {
			$selection = $_;
		}
	}

	$self->file1->Clear;
	$self->file1->Append( \@file1_list );
	$self->file1->SetSelection($selection);
	
	my @file2_list;
	if ( $self->{action_request} eq 'Patch' ) {
		@file2_list = $self->current_files('patch');
	} else {
		@file2_list = $self->current_files('saved');
	}

	$self->file2->Clear;
	$self->file2->Append( \@file2_list );
	$self->file2->SetSelection(0);
	
	#ToDo create against items on the fly
	my @vcs = [qw ( File-1 SVN Git CVS)];
	
	# this don't
	#$self->against->Clear;
	
	#ToDo how to add items
	# $self->against->Append( 4, \@vcs ); #Append fails
	# $self->against->SetStringSelection( 3, 'CVS');
	# $self->against->SetItemLabel(2, "Third");
	# $self->against->ItemDisable(2);
	# this works
	$self->against->SetSelection(1);
	
	return;
}

#######
# Event Handler process_clicked
#######
sub process_clicked {
	my $self = shift;

	my ( $file1, $file2 );

	my @items = $self->current_files();
	my @file1_list = $self->current_files('saved');	
	
	my @file2_list;
	if ( $self->{action_request} eq 'Patch' ) {
		@file2_list = $self->current_files('patch');
	} else {
		@file2_list = $self->current_files('saved');
	}
	
	$file1 = $file1_list[ $self->file1->GetSelection() ];
	$file2 = $file2_list[ $self->file2->GetCurrentSelection() ];

	TRACE( $self->action->GetStringSelection() ) if DEBUG;

	if ( $self->action->GetStringSelection() eq 'Patch' ) {
		$self->apply_patch( $file1, $file2 );
	}

	if ( $self->action->GetStringSelection() eq 'Diff' ) {

		if ( $self->against->GetStringSelection() eq 'File-2' ) {
			$self->make_patch_diff( $file1, $file2 );
		} elsif ( $self->against->GetStringSelection() eq 'SVN' ) {
			$self->make_patch_svn($file1);
		} elsif ( $self->against->GetStringSelection() eq 'Git' ) {
			$self->make_patch_git($file1);
		}
	}

	# reset dialog
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
		$self->against->SetSelection(0);

	}
	return;
}

#######
# Event Handler on_against
#######
sub on_against {
	my $self = shift;
	if ( $self->against->GetStringSelection() eq 'File' ) {
		$self->file2->Enable(1);
	} else {

		# SVN or Git
		$self->file2->Enable(0);
	}
	return;
}

#######
# Method current_files
#######
sub current_files {
	my $self         = shift;
	my $request_list = shift;
	my $main         = $self->main;
	my $current      = $main->current;
	my $notebook     = $current->notebook;
	my @label        = $notebook->labels;
	$self->{tab_cardinality} = scalar(@label) - 1;

	my $changed;

	for ( 0 .. $self->{tab_cardinality} ) {
		$self->{open_file_info}->{$_} = (
			{   'index'    => $_,
				'URL'      => $label[$_][1],
				'filename' => $notebook->GetPageText($_),
				'vcs'      => 'todo',

				# saved, changed, modified
				'current' => 'todo',
				'changed' => 0,
			},
		);

		if ( $notebook->GetPageText($_) =~ /^\*/ ) {
			say 'file changed from disk';
			$self->{open_file_info}->{$_}->{'changed'} = 1;
		}
	}

	my @order = sort { $label[$a][0] cmp $label[$b][0] } ( 0 .. $#label );

	my @display_names = ();

	if ( $request_list eq 'saved' ) {
		for ( 0 .. $self->{tab_cardinality} ) {
			unless ( $self->{open_file_info}->{$_}->{'changed'} || $self->{open_file_info}->{$_}->{'filename'} =~ /(patch|diff)$/ ) {
				push @display_names, $self->{open_file_info}->{$_}->{'filename'};
			}
		}
		return @display_names;
	}

	if ( $request_list eq 'patch' ) {
		for ( 0 .. $self->{tab_cardinality} ) {
			if ( $self->{open_file_info}->{$_}->{'filename'} =~ /(patch|diff)$/ ) {
				push @display_names, $self->{open_file_info}->{$_}->{'filename'};
			}
		}
		return @display_names;
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

		eval $main->setup_editor($patch_file);
		$main->info( Wx::gettext("Diff Succesful, you should see a new tab in editor called $patch_file") );
	} else {
		$main->info( Wx::gettext('Sorry Diff Failed, are you sure your choice of files was correct for this action') );
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
		unless ( $file2_url =~ /(patch|diff)$/ ) {
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
		eval $main->new_document_from_string( $our_patch => 'application/x-perl', );
		$main->info( Wx::gettext('Patch Succesful, you should see a new tab in editor called Unsaved #') );
	} else {
		$main->info( Wx::gettext('Sorry Patch Failed, are you sure your choice of files was correct for this action') );
	}

	return;
}

#######
# Composed Method
#
#######
sub filename_url {
	my $self     = shift;
	my $filename = shift;

	for ( 0 .. $self->{tab_cardinality} ) {
		if ( $self->{open_file_info}->{$_}->{'filename'} eq $filename ) {
			return $self->{open_file_info}->{$_}->{'URL'};
		}
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

	say "file1_url: $file1_url";

	if ( require SVN::Class ) {
		TRACE('found SVN::Class, Good to go') if DEBUG;

		my $file = SVN::Class::svn_file($file1_url);
		$file->diff;

		# TODO talk to Alias about supporting Data::Printer { caller_info => 1 }; in Padre::Logger
		# TRACE output is yuck
		TRACE( @{ $file->stdout } ) if DEBUG;
		my $diff_str = join "\n", @{ $file->stdout } ;

		TRACE($diff_str) if DEBUG;

		my $patch_file = $file1_url . '.patch';

		File::Slurp::write_file( $patch_file, $diff_str );
		TRACE("writing file: $patch_file") if DEBUG;

		$main->setup_editor($patch_file);
		$main->info( Wx::gettext("SVN Diff Succesful, you should see a new tab in editor called $patch_file") );
	} else {
		$main->info( Wx::gettext('Oops, might help if you install SVN::Class') );
	}

	return;
}

#######
# Method make_patch_git
#######
sub make_patch_git {
	my $self       = shift;
	my $file1_name = shift;
	my $main       = $self->main;

	my $file1_url = filename_url( $self, $file1_name );

	say 'Oops Git Yet To Be inplemented';
	$main->info( Wx::gettext('Oops, Git Yet To Be inplemented') );

	# if ( require Git ) {
	# TRACE('found SVN::Class, Good to go') if DEBUG;

# # 	my $file = SVN::Class::svn_file($dfile1);
	# $file->diff;

# # 	TRACE( @{ $file->stdout } ) if DEBUG;
	# my $diff_str = join( "\n", @{ $file->stdout } );

# # 	write_file( $patch_file, $diff_str );
	# TRACE("writing file: $patch_file") if DEBUG;

# # 	eval $main->setup_editor($patch_file);
	# $main->info( Wx::gettext("SVN Diff Succesful, you should see a new tab in editor called $patch_file") );
	# } else {
	# $main->info( Wx::gettext('Oops, might help if you install Git') );
	# }

	return;
}

1;

__END__

=head1 NAME

Padre::Plugin::Patch::Main::Main

=head1 VERSION

This document describes Padre::Plugin::Patch::Main version 0.22

=head1 DESCRIPTION

Main is the event handler for MainFB, it's parent class.

It displays a Main dialog with an about button.

=head1 SUBROUTINES/METHODS

=over 4

=item new

Constructor. Should be called with $main by Patch->load_dialog_main().

=item about_clicked

Event handler for button about

=item about_menu_clicked

for use with wx::frame todo

=item clean_clicked

passes request to dedicated method

=item clean_history

removes duplicate tuples, keeps newest, also remove missing files

=item clean_lastpositioninfile

removes files missing on system 

=item clean_session

removes empty sessions

=item clean_session_files

removes tuples which don't have a valid session reference

=item help_menu_clicked

for use with wx::frame todo

=item set_up

used 

=item show_clicked

Displays ALL the contents of selected relation in terminal with Data-Printer

=item update_clicked

Displays the contents of your chosen tuple using Padre DB schemes

=item width_adjust_clicked

Is a toggle to increase the width of the dialog of the viewing area

=back

=head1 AUTHOR

BOWTIE E<lt>kevin.dawson@btclick.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2011 The Padre development team as listed in Padre.pm.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
