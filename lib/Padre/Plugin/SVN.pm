package Padre::Plugin::SVN;

use 5.008;
use strict;
use warnings;

use Padre::Wx     ();
use Padre::Plugin ();

use Padre::Plugin::SVN::Info;
use Padre::Plugin::SVN::Dialog::Commit;

our $VERSION = '0.07';
our @ISA     = 'Padre::Plugin';


my $svn; # this holds the reference to the command class once instantiated.


#####################################################################
# Padre::Plugin Methods

sub plugin_name {
	'SVN';
}

sub padre_interfaces {
	 'Padre::Plugin' 		=> 0.91,
	 'Padre::Wx'       => 0.91,
	 'Padre::Wx::Icon' => 0.91,
}

sub plugin_enable {
	my $self = shift;
	require Padre::Plugin::SVN::Commands;
	$svn = Padre::Plugin::SVN::Commands->new();
	
	# check if we have svn installed;
	if( $svn->error ) {
		print "We do not have SVN\n";
		print $svn->error_msg;
		#$self->error( Wx::gettext('Could not find SVN command line on your system.') );
		
		
		#$self->plugin_disable;
	}
	else {
		print "SVN installed and ready to go\n";
		#$self->error( Wx::gettext('SVN installed and ready to go.') );
	}
}

# Clean up any of our children we loaded
sub plugin_disable {
	my $self = shift;
	$svn = undef;
	
	$self->unload('Padre::Plugin::SVN::Wx::BlameTree');
	$self->unload('Padre::Plugin::SVN::Wx::SVNDialog');
	$self->unload('Padre::Plugin::SVN::Commands');
	$self->unload('Padre::Plugin::SVN::Info');
	
	return 1;
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
	

		Wx::gettext('Commit') => [
			Wx::gettext('File') => sub {
				my $filename = $self->filename or return;
				$self->svn_commit($filename);
			},
			Wx::gettext('Project') => sub {
				my $project = $self->project or return;
				$self->svn_commit( $project->root );
			},
		],
		Wx::gettext('Diff') => [
			Wx::gettext('File') => [
				Wx::gettext('Show') => sub {
					my $filename = $self->filename or return;
					$self->svn_diff($filename);
				},
				Wx::gettext('Open in Padre') => sub {
					my $filename = $self->filename or return;
					$self->svn_diff_in_padre($filename);
				},
			],
			Wx::gettext('Project') => sub {
				my $project = $self->project or return;
				$self->svn_diff( $project->root );
			},
		],
		Wx::gettext('Log') => [
			Wx::gettext('File') => sub {
				my $filename = $self->filename or return;
				$self->svn_log($filename);
			},
			Wx::gettext('Project') => sub {
				my $project = $self->project or return;
				$self->svn_log( $project->root );
			},
		],
		'---' => undef,
		Wx::gettext('Revert File') => sub {
			$self->svn_revert;
		},
		Wx::gettext('Info') => sub {
			my $filename = $self->filename or return;
			$self->svn_info($filename);
		},
		
		Wx::gettext('Blame - Show who made changes')  => sub {
			my $filename = $self->filename or return;
			$self->svn_blame($filename);
		},
				
		
		
		Wx::gettext('About') => sub {
			$self->show_about;
		},
	];
	
}





#####################################################################
# General Methods

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::SVN");
	$about->SetDescription( <<"END_MESSAGE" );
Initial SVN support for Padre
END_MESSAGE
	$about->SetVersion($VERSION);

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}





######################################################################
# SVN Methods

# TODO Add in a timer so long running calls can be stopped at some point.

# TODO: update - this is tricky as you may end up with conflicts etc!

sub svn_commit {
	my $self = shift;
	my $path = shift;
	
	
	if( ! $svn->is_under_svn($path) ) {
		$self->main->error("$path is not under svn.");
		return 0;
	}
	
	#TODO grab the last revision details for the info bar.
	#my $info = "Get some info about the revision details of file etc";
	
	print "getting some info\n";
	$svn->svn_info($path);
	print "Path of the file\n";
	print $svn->info->path;
	my $info = $svn->info;
	my $main = $self->main;
	my $commit = Padre::Plugin::SVN::FBP::Commit->new($main, $info);
	
	$commit->ShowModal;

	# need to get commit message
	#while(1) {
		
		
		#require Padre::Plugin::SVN::Wx::SVNDialog;
		#my $dialog = Padre::Plugin::SVN::Wx::SVNDialog->new(
		#	$self->main,
		#	$info->path(),
		#	undef,
		#	'Commit File',
		#	1,
		#);
		#$dialog->ShowModal;	
		
		# check Cancel!!!!
		#return if $dialog->{cancelled};

		#my $message = $dialog->get_data;
		
		# whoops!! This isn't going to work "Commit message" is always set in the text control.
		#if ($message and $message ne 'Commit Message') { # "Commit Message" comes from SVNDialog
		#	$self->_do_commit($path, $message);
		#	last;
		#}
		#else {
		#	my $ret = Wx::MessageBox(
		#		Wx::gettext(
		#		'You really should commit with a useful message'
		#		.  "\n\nDo you really want to commit with out a message?"
		#		),
		#		Wx::gettext("Commit warning"),
		#		Wx::wxYES_NO | Wx::wxCENTRE,
		#		$self->main,
		#	);
			
		#	if( $ret == Wx::wxYES ) {
		#		$self->_do_commit($path, $message);
		#		last;
		#	}
		#	else {
		#		next;
		#	}
		#}
	
	#} # end while
	
	return 1;
	
	
}



sub _do_commit {
	my $self = shift;
	my $path = shift;
	my $message = shift;
	
	$svn->svn_commit($path, $message);
	if( $svn->error ) {
		$self->main->error( $svn->error_msg, "$path" );
	}
	else {
		$self->main->message( $svn->msg, "$path" );
	}
		
}	


sub svn_revert {
	my $self = shift;
	
	
	my $path = $self->filename;
	
	if( ! $svn->is_under_svn($path) ) {
		$self->main->error("$path is not under svn");
		return 0;
	}	
	
	# Firstly warn the person their actions will
	# go back to the last version of the file

	my $layout = [
		[
			[
				'Wx::StaticText',
				undef,
				"Warning!\n\nSVN Revert will revert the current file saved to the file system.\n\nIt will not change your current document if you have unsaved changes.\n\nReverting your changes means you will lose any changes made since your last SVN Commit."
			],
		],
		[
			[ 'Wx::Button', 'ok',     Wx::wxID_OK ],
			[ 'Wx::Button', 'cancel', Wx::wxID_CANCEL ]
		],
	];
	my $dialog = Wx::Perl::Dialog->new(
		parent => $self->main,
		title  => 'SVN Revert',
		layout => $layout,
		width  => [ 500, 1200 ],
	);
	$dialog->show_modal or return;
			my $data = $dialog->get_data;
	if ( $data->{cancel} ) {
		return;
	}
	
	# Continue with the revert
	
	$svn->svn_revert($path);	
	
}

sub svn_info {
	my $self = shift;
	my $path = shift;
	
	$svn->svn_info($path);
	if( ! $svn->error ) {
		$self->main->message( $svn->msg, "$path" );
	}
	else {
		$self->main->error( $svn->error_msg, "$path" );
	}
}

sub svn_diff {
	my $self = shift;
	my $path = shift;

	$svn->svn_diff($path);
	
	if( ! $svn->error ) {
		my $status = $svn->msg;
		
		require Padre::Plugin::SVN::Wx::SVNDialog;
		my $log = Padre::Plugin::SVN::Wx::SVNDialog->new(
			$self->main,
			$path,
			$status,
			'Diff',
		);
		$log->Show(1);
	}
	else {
		$self->error($svn->error);
	}
	
	return;
}

sub svn_diff_in_padre {
	my $self     = shift;
	my $path = shift;
	
	$svn->svn_diff($path);
	
	if( ! $svn->error ) {
		my $diff = $svn->msg || '';
		
		$self->main->new_document_from_string( $diff, 'text/x-patch' );
		return 1;
	}
	else {
		$self->error($svn->error);
	}
	
}


sub svn_log {
	my $self = shift;
	my $path = shift;

	if( ! $svn->is_under_svn($path) ) {
		$self->main->error("$path is not under svn");
		return 0;
	}	
	

	$self->{_busyCursor} = Wx::BusyCursor->new;
	$svn->svn_log($path);
	$self->{_busyCursor} = undef;

	if( $svn->error ) {
		
	}
	else {
		require Padre::Plugin::SVN::Wx::SVNDialog;
		my $log = Padre::Plugin::SVN::Wx::SVNDialog->new(
			$self->main,
			$path,
			$svn->msg,
			'Log',
		);
		$log->Show(1);
		
	}
}

sub svn_blame {
	my $self = shift;
	my $path = shift;

	if( ! $svn->is_under_svn($path) ) {
		$self->main->error("$path is not under svn");
		return 0;
	}
	
	$self->{_busyCursor} = Wx::BusyCursor->new;
	$svn->svn_blame($path);
	$self->{_busyCursor} = undef;
	if( $svn->error ) {
		
	}
	else {
		my @blame = split( /\n/, $svn->msg);
		
		require Padre::Plugin::SVN::Wx::SVNDialog;
		my $dialog = Padre::Plugin::SVN::Wx::SVNDialog->new(
			$self->main,
			$path,
			\@blame,
			'Blame',
		);
		
		$dialog->Show(1);
		return 1;
	}
}


######################################################################
# Support Methods

# TODO: I see this a lot. Should something like
# this be on Padre::Util?
sub filename {
	my $self     = shift;
	my $document = $self->current->document;
	my $filename = $document->filename;
	unless ( $filename ) {
		$self->error('File needs to be saved first.');
		return;
	}

	if ( $document->is_modified ) {
		my $ret = Wx::MessageBox(
			sprintf(
				Wx::gettext(
					'%s has not been saved but SVN would commit the file from disk.'
					. "\n\nDo you want to save the file first (No aborts commit)?"
				),
				$filename,
			),
			Wx::gettext("Commit warning"),
			Wx::wxYES_NO | Wx::wxCENTRE,
			$self->main,
		);

		return if $ret == Wx::wxNO;

		$self->main->on_save;
	}

	return $filename;
}

sub project {
	my $self    = shift;
	my $project = $self->current->project;
	unless ( $project ) {
		return $self->main->error( Wx::gettext('Could not find project root') );
	}
}

sub info {
	shift->main->info(@_);
}

sub error {
	shift->main->error(@_);
}

1;

=pod

=head1 NAME

Padre::Plugin::SVN - Simple SVN interface for Padre

=head1 SYNOPSIS

Requires SVN client tools to be installed.

cpan install Padre::Plugin::SVN

Acces it via Plugin/SVN

=head1 REQUIREMENTS

The plugin requires that the SVN client tools be installed and setup, this includes any cached authentication.

For most of the unices this is a matter of using the package manager to install the svn client tools.

For windows try: http://subversion.tigris.org/getting.html#windows.

=head2 Configuring the SVN client for cached authentication.

Because this module uses the installed SVN client, actions that require authentication from the server will fail and leave Padre looking as though it has hung.

The way to address this is to run the svn client from the command line when asked for the login and password details, enter as required.

Once done you should now have your authentication details cached.

More details can be found here: http://svnbook.red-bean.com/nightly/en/svn.serverconfig.netmodel.html#svn.serverconfig.netmodel.credcache

=head1 AUTHOR

Gabor Szabo E<lt>szabgab at gmail.comE<gt>

Additional work:

Peter Lavender E<lt>peter.lavender at gmail.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
