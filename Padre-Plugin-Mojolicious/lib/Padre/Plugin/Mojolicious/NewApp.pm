package Padre::Plugin::Mojolicious::NewApp;

# ABSTRACT: A New Mojolicious Application for Padre

use 5.008;
use strict;
use warnings;
use Cwd               ();
use File::Spec        ();
use Padre::Wx         ();
use Padre::Plugin::Mojolicious::FBP::NewApp ();
use Padre::DB         ();

our $VERSION = '0.06';

sub show {
	my $self = shift;
	my $config = $self->current->config;

	$self->{dir_picker}->SetPath( $config->module_start_directory );
	$self->{ok_button}->SetDefault;
	$self->{app_name}->SetFocus;
}

sub on_cancel_clicked {
	my $self = shift;
	$self->Destroy;
	
	return;
}

sub on_ok_clicked {
	my ($self, $event) = @_;
	$self->Destroy;

	my $main = $self->main;
	my $app_name = $self->{app_name}->GetValue;
	my $directory = $self->{dir_picker}->GetValue;

	# TODO improve input validation !
	if ( $app_name =~ m{^\s*$|[^\w\:]}o ) {
		Wx::MessageBox( Wx::gettext('Invalid Application name'), Wx::gettext('missing field'), Wx::wxOK, $main );
		return;
	} elsif ( not $directory ) {
		Wx::MessageBox(
			Wx::gettext('You need to select a base directory'), Wx::gettext('missing field'), Wx::wxOK,
			$main
		);
		return;
	}

	# We should probably call Mojolicious::Helper directly
	# (new() and mk_app()) here, as long as we can redirect
	# print statements to $main->output->AppendText().
	#
	# Perhaps if run_command() were to block before continuing,
	# we could use something like:
	#$main->run_command('mojolicious generate app' . $data->{'_app_name_'});

	# Prepare the output window for the output
	$main->show_output(1);
	$main->output->Remove( 0, $main->output->GetLastPosition );

	my @command = (
		'mojo',
		'generate',
		'app',
		$app_name,
	);

	# go to the selected directory
	my $pwd = Cwd::cwd();
	chdir $directory;

	# run command, then immediately restore directory
	my $output_text = qx(@command);
	chdir $pwd;

	$main->output->AppendText($output_text);

	my $ret = Wx::MessageBox(
		sprintf( Wx::gettext("%s apparently created. Do you want to open it now?"), $self->{_app_name_} ),
		Wx::gettext('Done'),
		Wx::wxYES_NO | Wx::wxCENTRE,
		$main,
	);
	if ( $ret == Wx::wxYES ) {
		require Padre::Plugin::Mojolicious::Util;
		my $file = Padre::Plugin::Mojolicious::Util::find_file_from_output(
			$app_name,
			$output_text
		);
		$file = Cwd::realpath($file); # avoid relative paths

		Padre::DB::History->create(
			type => 'files',
			name => $file,
		);
		$main->setup_editor($file);
		$main->refresh;
	}

	return;
}

1;
