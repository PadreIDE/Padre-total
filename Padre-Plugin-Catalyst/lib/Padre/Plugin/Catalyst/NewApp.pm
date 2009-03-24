package Padre::Plugin::Catalyst::NewApp;

use 5.008;
use strict;
use warnings;
use Cwd               ();
use File::Spec        ();
use Padre::Wx         ();
use Padre::Wx::Dialog ();

our $VERSION = '0.01';

sub on_newapp {
    my $main = Padre->ide->wx->main;
    
    my $dialog = dialog($main);
    $dialog->Show(1);
    return;
}

sub get_layout {

	my @layout = (
		[
			[ 'Wx::StaticText', undef,              'Application Name:'],
			[ 'Wx::TextCtrl',   '_app_name_',    ''],
		],
		[
			[ 'Wx::StaticText',      undef,         'Parent Directory:'],
			[ 'Wx::DirPickerCtrl',   '_directory_', '',   'Pick parent directory'],
		],
		[
			[ 'Wx::Button',     '_ok_',           Wx::wxID_OK     ],
			[ 'Wx::Button',     '_cancel_',       Wx::wxID_CANCEL ],
		],
	);
	return \@layout;
}

sub dialog {
    my $parent = shift;
    my $config = Padre->ide->config;
    
	my $layout = get_layout();
	my $dialog = Padre::Wx::Dialog->new(
		parent => $parent,
		title  => 'New Catalyst Application',
		layout => $layout,
		width  => [100, 200],
		bottom => 20,
	);
	
	$dialog->{_widgets_}->{_directory_}->SetPath($config->module_start_directory);
	
	$dialog->{_widgets_}->{_ok_}->SetDefault;
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}->{_ok_},      \&ok_clicked      );
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}->{_cancel_},  \&cancel_clicked  );

	$dialog->{_widgets_}->{_app_name_}->SetFocus;

	return $dialog;
}


sub cancel_clicked {
	my ($dialog, $event) = @_;

	$dialog->Destroy;

	return;
}

sub ok_clicked {
	my ($dialog, $event) = @_;

	my $data = $dialog->get_data;
	$dialog->Destroy;

	my $main = Padre->ide->wx->main;

	# TODO improve input validation !
	if ( $data->{'_app_name_'} =~ m{^\s*$|[^\w\:]} ) {
        Wx::MessageBox('Invalid Application name', 'missing field', Wx::wxOK, $main);
        return;
	}
	elsif (not $data->{'_directory_'}) {
	    Wx::MessageBox('You need to select a base directory', 'missing field', Wx::wxOK, $main);
        return;
	}

    # go to the selected directory
	my $pwd = Cwd::cwd();
	chdir $data->{_directory_};
	
	# We should probably call Catalyst::Helper directly
	# (new() and mk_app()) here, as long as we can redirect
	# print statements to $main->output->AppendText().
    #
    # Perhaps if run_command() were to block before continuing,
    # we could use something like:
	#$main->run_command('catalyst.pl ' . $data->{'_app_name_'});

	# Prepare the output window for the output
	$main->show_output(1);
	$main->output->Remove( 0, $main->output->GetLastPosition );

	my @command = (
            'catalyst.pl',
            $data->{'_app_name_'},
        );
	my $output_text = qx(@command);
	$main->output->AppendText($output_text);
	
	chdir $pwd;

	my $ret = Wx::MessageBox(
		sprintf("%s apparantly created. Do you want to open it now?", $data->{_app_name_}),
		'Done',
		Wx::wxYES_NO|Wx::wxCENTRE,
		$main,
	);
	if ( $ret == Wx::wxYES ) {
		# prepare Foo-Bar/lib/Foo/Bar/Controller/Root.pm
		my @parts = split('::', $data->{'_app_name_'});
		my $dir_name = join('-', @parts);
		my $file = File::Spec->catfile( $data->{_directory_}, 
                                        $dir_name, 
                                        'lib', 
                                        @parts,
                                        'Controller',
                                        'Root.pm'
                                      );
		Padre::DB::History->create(
			type => 'files',
			name => $file,
		);
		$main->setup_editor($file);
		$main->refresh;
	}

	return;
}
42;
__END__
# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.