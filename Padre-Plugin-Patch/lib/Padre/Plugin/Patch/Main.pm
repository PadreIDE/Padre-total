package Padre::Plugin::Patch::Main;

use 5.010;
use strict;
use warnings;

use utf8;
use autodie;

our $VERSION = '0.02';
use English qw( -no_match_vars );

use Padre::Logger;
use Padre::Wx       ();
use Padre::Wx::Main ();

use Data::Printer { caller_info => 1 };
use File::Slurp;

use parent qw( Padre::Plugin::Patch::FBP::MainFB );


#######
# new
#######
sub new {
	my $class = shift;
	my $main  = shift;

	# Create the dialog
	my $self = $class->SUPER::new($main);

	$self->CenterOnParent;
	$self->set_up;
	return $self;
}

#######
# Method set_up
#######
sub set_up {
	my $self = shift;
	my $main = $self->main;

	# TODO only saved files @items
	my @items;
	@items = $self->current_files();

	# SetSelection should be current file
	my $mcf = $main->current->filename;

	# SetSelection should be current file
	my $selection;
	for ( 0 .. @items ) {

		# TODO sort out error
		if ( $items[$_] eq $mcf ) {
			$selection = $_;
		}
	}

	# @items = Padre::Current->filename;
	$self->file1->Clear();
	$self->file1->Append( \@items );
	$self->file1->SetSelection($selection);

	# eval { @items = $self->current_files(); };
	$self->file2->Clear();
	$self->file2->Append( \@items );
	$self->file2->SetSelection(0);

	return;
}

#######
# Event Handler Button Show Clicked
#######
sub process_clicked {
	my $self = shift;

	# say 'process_clicked';
	my ( $file1, $file2 );

	my @items = $self->current_files();

	$file1 = $items[ $self->file1->GetSelection() ];
	$file2 = $items[ $self->file2->GetSelection() ];

	TRACE( $self->action->GetStringSelection() ) if DEBUG;

	if ( $self->action->GetStringSelection() eq 'Patch' ) {
		$self->apply_patch( $file1, $file2 );
	}

	if ( $self->action->GetStringSelection() eq 'Diff' ) {

		if ( $self->file2svn->GetStringSelection() eq 'File' ) {
			$self->make_patch( $file1, $file2 );
		} elsif ( $self->file2svn->GetStringSelection() eq 'SVN' ) {
			$self->make_patch_svn($file1);
		}
	}

	# reset dialog
	$self->set_up;

	return;
}




#######
# Method current_files
#######
sub current_files {
	my $self = shift;

	my $main     = $self->main;
	my $current  = $main->current;
	my $notebook = $current->notebook;

	my @label = $notebook->labels;

	# p @label;

	my @order = sort { $label[$a][0] cmp $label[$b][0] } ( 0 .. $#label );

	my @display_names;
	foreach (@order) {
		push @display_names, $label[$_][1];
	}

	return @display_names;
}

#######
# Method make_patch
#######
sub make_patch {
	my ( $self, $dfile1, $dfile2 ) = @ARG;
	my $main = $self->main;

	if ( -e $dfile1 ) {
		TRACE("found 1: $dfile1") if DEBUG;
	}

	if ( -e $dfile2 ) {
		TRACE("found 2: $dfile2") if DEBUG;
	}

	if ( -e $dfile1 && -e $dfile2 ) {
		require Text::Diff;
		my $our_diff;
		eval { $our_diff = Text::Diff::diff( $dfile1, $dfile2, { STYLE => 'Unified' } ); };
		TRACE($our_diff) if DEBUG;

		# This works though
		my $patch_file = $dfile1 . '.patch';

		write_file( $patch_file, $our_diff );
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
	my ( $self, $pfile1, $patch ) = @ARG;
	my $main = $self->main;

	my ( $source, $diff );

	if ( -e $pfile1 ) {
		TRACE("found 1: $pfile1") if DEBUG;
		$source = read_file($pfile1);
	}

	if ( -e $patch ) {
		TRACE("found 2: $patch") if DEBUG;
		$diff = read_file($patch);
	}

	if ( -e $pfile1 && -e $patch ) {

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
# Event on_action
#######
sub make_patch_svn {
	my ( $self, $dfile1 ) = @ARG;
	my $main = $self->main;

	if ( require SVN::Class ) {
		TRACE('found SVN::Class, Good to go') if DEBUG;

		require SVN::Class;
		my $file = SVN::Class::svn_file($dfile1);
		$file->diff;
		my $diff_str = join( "\n", @{ $file->stdout } );

		TRACE($diff_str) if DEBUG;

		# eval $self->main->new_document_from_string( $diff_str, 'text/x-patch' );

		my $patch_file = $dfile1 . '.patch';

		write_file( $patch_file, $diff_str );
		TRACE("writing file: $patch_file") if DEBUG;

		eval $main->setup_editor($patch_file);
		$main->info( Wx::gettext("SVN Diff Succesful, you should see a new tab in editor called $patch_file") );
	} else {
		$main->info( Wx::gettext('Oops, might help if you install SVN::Class') );
	}
	
	return;
}


1;

__END__

=head1 NAME

Padre::Plugin::Cookbook::Recipe04::Main

=head1 VERSION

This document describes Padre::Plugin::Cookbook::Recipe04::Main version 0.22

=head1 DESCRIPTION

Recipe04 - ConfigDB

Main is the event handler for MainFB, it's parent class.

It displays a Main dialog with an about button.
It's a basic example of a Padre plug-in using a WxDialog.

=head1 SUBROUTINES/METHODS

=over 4

=item new / BUILD

Constructor. Should be called with $main by CookBook->load_dialog_main().

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

=item load_dialog_about ()

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe04::About;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe04::About->new( $main );
    $self->{dialog}->Show;

=item plugin_disable ()

Required method with minimum requirements

    $self->unload('Padre::Plugin::Cookbook::Recipe04::About');
    $self->unload('Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB');

=item set_up

used 

=item show_clicked

Displays ALL the contents of selected relation in terminal with Data-Printer

=item update_clicked

Displays the contents of your chosen tuple using Padre DB schemes

=item width_adjust_clicked

Is a toggle to increase the width of the dialog of the viewing area


=back

=head1 DEPENDENCIES

Padre::Plugin::Cookbook, Padre::Plugin::Cookbook::Recipe04::FBP::MainFB, 
Padre::Plugin::Cookbook::Recipe04::About, Padre::Plugin::Cookbook::Recipe0::FBP::AboutFB
Data::Printer

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
