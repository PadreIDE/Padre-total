package Padre::Plugin::Dancer;

# ABSTRACT: Dancer helper interface for Padre
use v5.10;
use warnings;
use strict;

our $VERSION = '0.01';

use Padre::Unload ();
use Padre::Perl   ();

# use base 'Padre::Plugin';
use parent qw{
	Padre::Plugin
};


#######
# Define Plugin Name Spell Checker
#######
sub plugin_name {
	return Wx::gettext('Dancer');
}

#######
# Define Padre Interfaces required
#######
sub padre_interfaces {
	return (
		'Padre::Plugin' => '0.94',

		# 'Padre::Task'   => '0.94',
		'Padre::Unload' => '0.94',
		'Padre::Perl'   => '0.94',

		# used by my sub packages
		# 'Padre::Locale'         => '0.96',
		# 'Padre::Logger' => '0.94',

		# 'Padre::Wx'             => '0.96',
		# 'Padre::Wx::Role::Main' => '0.96',
		# 'Padre::Util'           => '0.97',
	);
}




# The plugin name to show in the Plugin Manager and menus
# sub plugin_name {'Dancer'}

# Declare the Padre interfaces this plugin uses
# sub padre_interfaces {
# 'Padre::Plugin' => '0.91',;
# }

# TODO: see the Catalyst plugin for inspiration
# sub plugin_icon {
#	my $icon =
#	return Wx::Bitmap->newFromXPM($icon);
#}


sub menu_plugins_simple {
	my $self = shift;

	return (
		Wx::gettext('Dancer') => [
			Wx::gettext('New Dancer...') => [
				Wx::gettext('Application'), sub { $self->new_dancer_app },
			],
			Wx::gettext('Start Web Server'),
			sub { $self->on_start_server },
			Wx::gettext('Stop Web Server'),
			sub { $self->on_stop_server },

			Wx::gettext('Dancer Online References') => [
				Wx::gettext('Dancer Website'),
				sub {
					Padre::Wx::launch_browser('http://www.perldancer.org/');
				},
				Wx::gettext('Dance Community Live Support'),
				sub {
					Padre::Wx::launch_irc('dancer');
				},
			],
			Wx::gettext('About'),
			sub {
				$self->on_show_about;
			},
		],
	);
}

#Wx::gettext('Beginner\'s Tutorial')
#Wx::gettext('Overview'),
#sub { Padre::Wx::launch_browser('http://search.cpan.org/perldoc?Catalyst::Manual::Tutorial'); }

sub new_dancer_app {
	require Padre::Plugin::Dancer::NewApp;
	Padre::Plugin::Dancer::NewApp::on_newapp();

	# ask the name of the application
	# ask the parent directory in which we should create the tree
	return;
}



sub on_start_server {
	my $self = shift;

	my $main = Padre->ide->wx->main;

	require File::Spec;
	require Padre::Plugin::Catalyst::Util;
	my $project_dir = Padre::Plugin::Catalyst::Util::get_document_base_dir() || return;

	my $server_filename = Padre::Plugin::Catalyst::Util::get_catalyst_project_name($project_dir);

	$server_filename .= '_server.pl';

	my $server_full_path = File::Spec->catfile( $project_dir, 'script', $server_filename );
	if ( !-e $server_full_path ) {
		Wx::MessageBox(
			sprintf(
				Wx::gettext(
					"Catalyst development web server not found at\n%s\n\nPlease make sure the active document is from your Catalyst project."
				),
				$server_full_path
			),
			Wx::gettext('Server not found'),
			Wx::wxOK, $main
		);
		return;
	}

	# go to the selected file's directory
	# (catalyst instructs us to always run their scripts
	#  from the basedir)
	my $pwd = Cwd::cwd();
	chdir $project_dir;

	my $perl = Padre::Perl->perl;
	my $command = "$perl " . File::Spec->catfile( 'script', $server_filename );
	$command .= ' -r ' if $self->panel->{checkbox}->IsChecked;

	#$main->run_command($command);
	# somewhat the same as $main->run_command,
	# but in our very own panel, and with our own rigs
	$self->run_command($command);

	# restore current dir
	chdir $pwd;

	# handle menu graying
	Padre::Plugin::Catalyst::Util::toggle_server_menu(0);
	$self->panel->toggle_panel(0);

	# TODO: actually check whether this is true.
	my $ret = Wx::MessageBox(
		Wx::gettext('Web server appears to be running. Launch web browser now?'),
		Wx::gettext('Start Web Browser?'),
		Wx::wxYES_NO | Wx::wxCENTRE,
		$main,
	);
	if ( $ret == Wx::wxYES ) {
		Padre::Wx::launch_browser('http://localhost:3000');
	}

	return;
}


### run_command() adapted from Padre::Wx::Main's version
sub run_command {
	my ( $self, $command ) = (@_);

	# clear the panel
	$self->panel->output->Remove( 0, $self->panel->output->GetLastPosition );

	# If this is the first time a command has been run,
	# set up the ProcessStream bindings.
	unless ($Wx::Perl::ProcessStream::VERSION) {
		require Wx::Perl::ProcessStream;
		if ( $Wx::Perl::ProcessStream::VERSION < .20 ) {
			$self->main->error(
				sprintf(
					Wx::gettext(
						      'Wx::Perl::ProcessStream is version %s'
							. ' which is known to cause problems. Get at least 0.20 by typing'
							. "\ncpan Wx::Perl::ProcessStream"
					),
					$Wx::Perl::ProcessStream::VERSION
				)
			);
			return 1;
		}

		Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_STDOUT(
			$self->panel->output,
			sub {
				$_[1]->Skip(1);
				my $outpanel = $_[0]; #->{panel};
				$outpanel->style_good;
				$outpanel->AppendText( $_[1]->GetLine . "\n" );
				return;
			},
		);
		Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_STDERR(
			$self->panel->output,
			sub {
				$_[1]->Skip(1);
				my $outpanel = $_[0]; #->{panel};
				$outpanel->style_neutral;
				$outpanel->AppendText( $_[1]->GetLine . "\n" );

				return;
			},
		);
		Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_EXIT(
			$self->panel->output,
			sub {
				$_[1]->Skip(1);
				$_[1]->GetProcess->Destroy;
				delete $self->{server};
			},
		);
	}

	# Start the command
	my $process = Wx::Perl::ProcessStream::Process->new(
		$command,
		"Run $command",
		$self->panel->output
	);
	$self->{server} = $process->Run;

	# Check if we started the process or not
	unless ( $self->{server} ) {

		# Failed to start the command. Clean up.
		Wx::MessageBox(
			sprintf( Wx::gettext("Failed to start server via '%s'"), $command ),
			Wx::gettext("Error"), Wx::wxOK, $self
		);

		#		$self->menu->run->enable;
	}

	return;
}

sub on_stop_server {
	my $self = shift;

	if ( $self->{server} ) {
		my $processid = $self->{server}->GetProcessId();
		kill( 9, $processid );

		#$self->{server}->TerminateProcess;
	}
	delete $self->{server};

	$self->panel->output->AppendText( "\n" . Wx::gettext('Web server stopped successfully.') . "\n" );

	# handle menu graying
	require Padre::Plugin::Catalyst::Util;
	Padre::Plugin::Catalyst::Util::toggle_server_menu(1);
	$self->panel->toggle_panel(1);

	return;
}

sub on_show_about {
	require Dancer;
	require Class::Unload;
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Dancer");
	$about->SetDescription( Wx::gettext('Dancer support for Padre') . "\n\n"
			. Wx::gettext('This system is running Dancer version')
			. " $Dancer::VERSION\n" );
	$about->SetVersion($Padre::Plugin::Dancer::VERSION);
	Class::Unload->unload('Dancer');

	Wx::AboutBox($about);
	return;
}

# sub plugin_enable {
	# my $self = shift;

	# return;
# }


sub plugin_disable {
	my $self = shift;

	# $self->on_stop_server;


	# cleanup loaded classes
	require Class::Unload;
	Class::Unload->unload('Dancer');
}


1;

__END__

=head1 SYNOPSIS

	cpan install Padre::Plugin::Dancer;

Then use it via L<Padre>, The Perl IDE.

=head1 IDEAS WANTED!

How can this Plugin further improve your Dancer development experience? Please let us know! We are always looking for new ideas and wishlists on how to improve it even more, so drop us a line via email, RT or by joining us via IRC in #padre, right at irc.perl.org (if you are using Padre, you can do this by choosing 'Help->Live Support->Padre Support').

=head1 DESCRIPTION

As all Padre plugins, after installation you need to enable it via "Plugins->Plugin Manager".

You'll also get a brand new menu (Plugins->Dancer) with the following options:

=head2 'Start Web Server'

This option will automatically spawn your application's development web server. Once it's started, it will ask to open your default web browser to view your application running.

=head2 'Stop Web Server'

This option will stop the development web server for you.

=head2 'Dancer Online References'

This menu option contains a series of external reference links on Dancer. Clicking on each of them will point your default web browser to their websites.

=head2 'About'

Shows a nice about box with this module's name and version, as well as your installed Dancer version.

=head1 TRANSLATIONS

This plugin has been translated to the folowing languages (alphabetic order):

=over 4


=back

Plugin was based on the Catalyst plugin.

Many thanks to all contributors!

Feel free to help if you find any of the translations need improvement/updating, or if you can add more languages to this list. Thanks!

=head1 BUGS

Please report any bugs or feature requests in the bug tracking system of Padre: L<http://padre.perlide.org/trac>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Padre::Plugin::Dancer

=head1 SEE ALSO

L<Dancer>, L<Padre>

=cut
