package Padre::Plugin::SVN;

use 5.008;
use strict;
use warnings;
use Padre::Wx     ();
use Padre::Plugin ();

our $VERSION = '0.06';
our @ISA     = 'Padre::Plugin';


my $svn; # this holds the reference to the command class once instantiated.


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
	$self->unload('Padre::Plugin::SVN::Wx::BlameTree');
	$self->unload('Padre::Plugin::SVN::Wx::SVNDialog');
	$self->uload('Padre::Plugin::SVN::Commands');
	
	return 1;
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
	
	
		Wx::gettext('Info') => sub {
			my $filename = $self->filename or return;
			$self->get_info($filename);
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

# TODO: update!

sub get_info {
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
