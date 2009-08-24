package Padre::Plugin::SVN;

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();
use Padre::Util   ();



use SVN::Class;

our $VERSION = '0.02';
our @ISA     = 'Padre::Plugin';

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

Gabor Szabo, C<< <szabgab at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

#####################################################################
# Padre::Plugin Methods

# need to setup the toolbar and put it in the ide
sub plugin_enable {
	
	my $self = shift;
	#my $main = Padre->ide->wx->main;
	#$self->{tb} = Padre::Plugin::SVN::Wx::Toolbar->new($main);
	#$main->SetToolBar( $self->{tb} );
	#$main->GetToolBar->Realize;
	
	#$main->{toolbar_panel}->{vbox}->Add( $self->{tb}, Wx::wxALL | Wx::wxALIGN_LEFT | Wx::wxEXPAND,4 );
	
}

# remove the toolbar from the ide
sub plugin_disable {
	my $self = shift;
	
	# not ideal... 
	#$self->{tb} = undef;
	
	
}

sub padre_interfaces {
	'Padre::Plugin' => 0.43;
}

sub plugin_name {
	'SVN';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About'     => sub { $self->show_about },
		'File'		=> [
			'Add'	=> sub { $self->svn_add },
			'Blame'	=> sub { $self->svn_blame },
			'Commit'=> sub { $self->svn_commit_file },
			'Diff'	=> [ 	'Show' 		=> sub { $self->svn_diff_of_file },
					'Open in Padre' => sub { $self->svn_diff_in_padre },
				],
			'Log'	=> sub { $self->svn_log_of_file },
			'Status'=> sub { $self->svn_status_of_file },

		],
#		'Project - Not Implemented'	=> [],
#		'Commit...' => [
#			'File'    => sub { $self->svn_commit_file },
#			'Project' => sub { $self->svn_commit_project },
#		],
#		'Blame'	=> [
#			'File'	=> sub { $self->svn_blame },
#		],
#		'Status...' => [
#			'File'    => sub { $self->svn_status_of_file },
#			'Project' => sub { $self->svn_status_of_project },
#		],
#		'Log...' => [
#			'File'    => sub { $self->svn_log_of_file },
#			'Project' => sub { $self->svn_log_of_project },
#		],
#		'Diff...' => [
#			'File'    => [ 'Show Diff' => sub { $self->svn_diff_of_file }, 'Open in Padre' => sub {$self->svn_diff_in_padre } ],
#			'Dir'     => sub { $self->svn_diff_of_dir },
#			'Project' => sub { $self->svn_diff_of_project },
#		],
#		'Add...' => [
#			'File' => sub { $self->svn_add_file },
#
#			#			'Dir'     => sub { $self->svn_diff_of_dir },
#			#			'Project' => sub { $self->svn_diff_of_project },
#		],
#
	];
}

#####################################################################
# Custom Methods

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

# TODO: I see this a lot. Should something like
# this be on Padre::Util?
sub _get_current_filename {
	my $main = Padre->ide->wx->main;
	my $filename = $main->current->document->filename;
	if ($filename) {
		return $filename;
	}
	else {
		$main->error('File needs to be saved first');
		return;
	}
}

sub svn_blame {
	my( $self ) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		my $main = Padre::Current->main;
		$self->{_busyCursor} = Wx::BusyCursor->new();
		my $file = svn_file($filename);
		$file->blame();
		$self->{_busyCursor} = undef;
		my $blame = join( "\n", @{$file->stdout} );
		require Padre::Plugin::SVN::Wx::SVNDialog;
		my $dialog = Padre::Plugin::SVN::Wx::SVNDialog->new($main, $filename, $blame, 'Blame');
		$dialog->Show(1);
		return 1;
	}
	
	return;
	
}

sub svn_status {
	my ( $self, $path ) = @_;
	my $main   = Padre->ide->wx->main;

	my $file = svn_file( $path );
	
	my $info = "";
	
	if( $file->info ) {
		#print $file->info->dump();
		$info .= "Author: " . $file->info->{author} . "\n";
		$info .= "File Name: " . $file->info->{name} . "\n";
		$info .= "Last Revision: " . $file->info->{last_rev} . "\n";
		$info .= "Current Revision: " . $file->info->{rev} . "\n\n";
				
		$info .= "File create Date: " . $file->info->{date} . "\n\n";
				
		$info .= "Last Updated: "  . $file->info->{updated} . "\n\n";
		
		$info .= "File Path: " . $file->info->{path} . "\n";
		$info .= "File URL: " . $file->info->{_url} . "\n";
		$info .= "File Root: " . $file->info->{root} . "\n\n";
				
		$info .= "Check Sum: " . $file->info->{checksum} . "\n";
		$info .= "UUID: " . $file->info->{uuid} . "\n";
		$info .= "Schedule: " . $file->info->{schedule} . "\n";
		$info .= "Node: " . $file->info->{node} . "\n\n";
	}
	else {
		$info .= 'File is not managed by SVN';
	}
	#print $info;
	$main->message( $info, "$path" );
	return;
}

sub svn_status_of_file {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		$self->svn_status($filename);
	}
	return;
}

sub svn_status_of_project {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		my $main     = Padre::Current->main;
		my $dir      = Padre::Util::get_project_dir($filename);
		return $main->error("Could not find project root") if not $dir;
		$self->svn_status($dir);
	}
	return;
}


sub svn_log {
	my ( $self, $path ) = @_;
	my $main   = Padre->ide->wx->main;
	
	my $file = svn_file($path);
	$self->{_busyCursor} = Wx::BusyCursor->new();
	my $out = join( "\n", @{ $file->log() } );
	$self->{_busyCursor} = undef;
	#$main->message( $out, "$path" );
	require Padre::Plugin::SVN::Wx::SVNDialog;
	my $log = Padre::Plugin::SVN::Wx::SVNDialog->new($main, $path, $out, 'Log');
	$log->Show(1);

	
}

sub svn_log_of_file {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		$self->svn_log($filename);
	}
	return;
}

sub svn_log_of_project {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		my $main     = Padre::Current->main;
		my $dir      = Padre::Util::get_project_dir($filename);
		return $main->error("Could not find project root") if not $dir;
		$self->svn_log($dir);
	}
	return;
}




sub svn_diff {
	my ( $self, $path ) = @_;
	my $main   = Padre->ide->wx->main;
	
	my $file = svn_file($path);
	#print $file->stderr;
	#print $file->stdout;
	
	$file->diff();
	my $status  = join( "\n", @{$file->stdout} );
	#$main->message( $status, "$path" );
	require Padre::Plugin::SVN::Wx::SVNDialog;
	my $log = Padre::Plugin::SVN::Wx::SVNDialog->new($main, $path, $status, 'Diff');
	$log->Show(1);
	
	return;
	
}

sub svn_diff_in_padre {
	my ($self) = @_;
	my $filename = _get_current_filename();
	my $main = Padre->ide->wx->main;
	
	
	if( $filename ) {
		my $file = svn_file($filename);
		my $diff = $file->diff;
		my $diff_str = join( "\n", @{$file->stdout} );
		$main->new_document_from_string($diff_str, 'text/x-patch');
		return 1;
	}
	return;
	
}

sub svn_diff_of_file {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		$self->svn_diff($filename);
	}
	return;
}

sub svn_diff_of_project {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		my $dir = Padre::Util::get_project_dir($filename);
		$self->svn_diff($dir);
	}
	return;
}

sub svn_commit {
	my ( $self, $path ) = @_;

	my $main = Padre->ide->wx->main;
	my $file = svn_file($path);
	
	my $info = "$path\n\n";
	$info .= "Last Revision: " . $file->info->{last_rev};
	#my $message = $main->prompt( "SVN Commit of $path", "Please type in your message", "MY_SVN_COMMIT" );
	require Padre::Plugin::SVN::Wx::SVNDialog;
	my $dialog = Padre::Plugin::SVN::Wx::SVNDialog->new($main, $info, undef, 'Commit File', 1);
	$dialog->ShowModal;
	
	my $message = $dialog->get_data;
	
	if ($message) {
		$self->{_busyCursor} = Wx::BusyCursor->new();

		my $revNo = $file->commit($message);
		
		$self->{_busyCursor} = undef;
		
		my @commit = @{$file->stdout};
		my @err = @{$file->stderr};
		if( @err ) {
			$main->error( join("\n", @err), 'Error - SVN Commit' );
		}
		else {
			$main->message( join("\n", @commit), "Committed Revision number $revNo" );
		}
	
	}
	
	return;
}

sub svn_commit_file {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		$self->svn_commit($filename);
	}
	return;
}

sub svn_commit_project {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		my $dir = Padre::Util::get_project_dir($filename);
		$self->svn_commit($dir);
	}
	return;
}

sub svn_add {
	my ( $self, $path ) = @_;
	my $main = Padre->ide->wx->main;
	
	my $file = svn_file($path);
	$file->add;
	my $msg = "$path scheduled to be added to " . $file->info->{_url};
	$main->message( $msg );

	return;
}

sub svn_add_file {
	my ($self)   = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		$self->svn_add($filename);
	}
	return;
}

1;

