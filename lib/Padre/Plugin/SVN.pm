package Padre::Plugin::SVN;

use 5.008;
use strict;
use warnings;
use Padre::Wx     ();
use Padre::Plugin ();

our $VERSION = '0.05';
our @ISA     = 'Padre::Plugin';





#####################################################################
# Padre::Plugin Methods

sub plugin_name {
	'SVN';
}

sub padre_interfaces {
	'Padre::Plugin'     => 0.81,
	'Padre::Wx'         => 0.81,
	'Padre::Wx::Icon'   => 0.81,
	'Padre::Wx::Dialog' => 0.81,
}

# Clean up any of our children we loaded
sub plugin_disable {
	my $self = shift;
	$self->unload('Padre::Plugin::SVN::Wx::BlameTree');
	$self->unload('Padre::Plugin::SVN::Wx::SVNDialog');
	return 1;
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		# Maybe reorganize according to File/Directory/Project ?
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

		'---' => undef,

		Wx::gettext('Add') => [
			Wx::gettext('File') => sub {
				my $filename = $self->filename or return;
				$self->svn_add($filename);
			},
		],

		'---' => undef,

		Wx::gettext('Revert') => sub {
			$self->svn_revert;
		},

		'---' => undef,

		Wx::gettext('Status') => [
			Wx::gettext('File') => sub {
				my $filename = $self->filename or return;
				$self->svn_status($filename);
			},
			Wx::gettext('Project') => sub {
				my $project = $self->project or return;
				$self->svn_status( $project->root );
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

		Wx::gettext('Diff') => [
			Wx::gettext('File') => [
				Wx::gettext('Show') => sub {
					my $filename = $self->filename or return;
					$self->svn_diff($filename);
				},
				Wx::gettext('Open in Padre') => sub {
					$self->svn_diff_in_padre;
				},
			],
			Wx::gettext('Project') => sub {
				my $project = $self->project or return;
				$self->svn_diff( $project->root );
			},
		],

		Wx::gettext('Blame')  => sub {
			$self->svn_blame;
		},

		'---' => undef,

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

# TODO: update!

sub svn_file {
	# Simple method wrapper around SVN::Class::svn_file that run-time loads
	require SVN::Class;
	SVN::Class::svn_file($_[1]);
}

sub svn_revert {
	my $self = shift;

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
	my $filename = $self->filename or return;
	my $file     = $self->svn_file($filename);
	$file->revert;
}

sub svn_blame {
	my $self     = shift;
	my $filename = $self->filename or return;

	$self->{_busyCursor} = Wx::BusyCursor->new;
	my $file = $self->svn_file($filename);
	$file->blame;

	my @blame = @{ $file->stdout };
	require Padre::Plugin::SVN::Wx::SVNDialog;
	my $dialog = Padre::Plugin::SVN::Wx::SVNDialog->new(
		$self->main,
		$filename,
		\@blame,
		'Blame',
	);
	$self->{_busyCursor} = undef;
	$dialog->Show(1);
	return 1;
}

sub svn_status {
	my $self = shift;
	my $path = shift;
	my $file = $self->svn_file($path);
	my $info = "";

	if ( $file->info ) {
		$info .= "Author: " . $file->info->{author} . "\n";
		$info .= "File Name: " . $file->info->{name} . "\n";
		$info .= "Last Revision: " . $file->info->{last_rev} . "\n";
		$info .= "Current Revision: " . $file->info->{rev} . "\n\n";
		$info .= "File create Date: " . $file->info->{date} . "\n\n";
		$info .= "Last Updated: " . $file->info->{updated} . "\n\n";
		$info .= "File Path: " . $file->info->{path} . "\n";
		$info .= "File URL: " . $file->info->{_url} . "\n";
		$info .= "File Root: " . $file->info->{root} . "\n\n";
		$info .= "Check Sum: " . $file->info->{checksum} . "\n";
		$info .= "UUID: " . $file->info->{uuid} . "\n";
		$info .= "Schedule: " . $file->info->{schedule} . "\n";
		$info .= "Node: " . $file->info->{node} . "\n\n";
	} else {
		$info .= 'File is not managed by SVN';
	}

	$self->main->message( $info, "$path" );
	return;
}

sub svn_log {
	my $self = shift;
	my $path = shift;
	my $file = $self->svn_file($path);

	$self->{_busyCursor} = Wx::BusyCursor->new;
	my $out = join( "\n", @{ $file->log } );
	$self->{_busyCursor} = undef;

	require Padre::Plugin::SVN::Wx::SVNDialog;
	my $log = Padre::Plugin::SVN::Wx::SVNDialog->new(
		$self->main,
		$path,
		$out,
		'Log',
	);
	$log->Show(1);
}

sub svn_diff {
	my $self = shift;
	my $path = shift;
	my $file = $self->svn_file($path);

	$file->diff;
	my $status = join( "\n", @{ $file->stdout } );

	require Padre::Plugin::SVN::Wx::SVNDialog;
	my $log = Padre::Plugin::SVN::Wx::SVNDialog->new(
		$self->main,
		$path,
		$status,
		'Diff',
	);
	$log->Show(1);

	return;
}

sub svn_diff_in_padre {
	my $self     = shift;
	my $filename = $self->filename or return;
	my $file     = $self->svn_file($filename);
	my $diff     = $file->diff;
	my $diff_str = join( "\n", @{ $file->stdout } );
	$self->main->new_document_from_string( $diff_str, 'text/x-patch' );
	return 1;
}

sub svn_commit {
	my $self = shift;
	my $path = shift;
	my $file = $self->svn_file($path);

# 	== 0 seems to produce false errors here
	unless ( defined $file ) {
		$self->error(Wx::gettext('Unable to find SVN file!'),Wx::gettext('Error - SVN Commit'));
		return;
	}

	my $info = "$path\n\n";
	if ( defined( $file->info->{last_rev} ) ) {
		$info .= "Last Revision: " . $file->info->{last_rev};
	} else {
		# New files
		$info .= "Last Revision: (none)";
	}

	require Padre::Plugin::SVN::Wx::SVNDialog;
	my $dialog = Padre::Plugin::SVN::Wx::SVNDialog->new(
		$self->main,
		$info,
		undef,
		'Commit File',
		1,
	);
	$dialog->ShowModal;

	# check Cancel!!!!
	return if $dialog->{cancelled};

	my $message = $dialog->get_data;

	# whoops!! This isn't going to work "Commit message" is always set in the text control.
	if ($message and $message ne 'Commit Message') { # "Commit Message" come from SVNDialog
		$self->{_busyCursor} = Wx::BusyCursor->new;

		my $revNo = $file->commit($message);

		$self->{_busyCursor} = undef;

		my @commit = @{ $file->stdout };
		my @err    = @{ $file->stderr };
		if (@err) {
			$self->error( join( "\n", @err ), Wx::gettext('Error - SVN Commit') );
		} else {
			$self->info( join( "\n", @commit ), "Committed Revision number $revNo." );
		}

	} else {
		my $ret = Wx::MessageBox(
			Wx::gettext(
			'You really should commit with a useful message'
			.  "\n\nDo you really want to commit with out a message?"
			),
			Wx::gettext("Commit warning"),
			Wx::wxYES_NO | Wx::wxCENTRE,
			$self->main,
		);
		if( $ret == Wx::wxYES ) {
			$self->{_busyCursor} = Wx::BusyCursor->new;
			my $revNo = $file->commit($message);
			$self->{_busyCursor} = undef;

			my @commit = @{ $file->stdout };
			my @err    = @{ $file->stderr };
			if (@err) {
				$self->error( join( "\n", @err ), 'Error - SVN Commit' );
			} else {
				$self->info( join( "\n", @commit ), "Committed Revision number $revNo." );
			}
		} else {
			$self->svn_commit($path);
		}
	}

	return;
}

sub svn_add {
	my $self = shift;
	my $path = shift;
	my $file = $self->svn_file($path);

	$file->add;
	if ($file->errstr) {
		$self->error($file->errstr);
	} else {
		$self->info("$path scheduled to be added to " . $file->info->{_url});
	}

	return;
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
