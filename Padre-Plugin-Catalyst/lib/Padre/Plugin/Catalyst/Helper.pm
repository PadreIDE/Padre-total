package Padre::Plugin::Catalyst::Helper;

use 5.008;
use strict;
use warnings;
use Cwd               ();
use File::Spec        ();
use Padre::Wx         ();
use Padre::Wx::Dialog ();

our $VERSION = '0.01';

sub dialog {
    my $layout = shift;
    my $ok_sub = shift;
    
    my $main   = Padre->ide->wx->main;
    my $config = Padre->ide->config;
    
	my $dialog = Padre::Wx::Dialog->new(
		parent => $main,
		title  => 'Create New Component',
		layout => $layout,
		width  => [100, 200],
		bottom => 20,
	);

	$dialog->{_widgets_}->{_ok_}->SetDefault;
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}->{_ok_},      $ok_sub           );
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}->{_cancel_},  \&cancel_clicked  );

	$dialog->{_widgets_}->{_name_}->SetFocus;

	return $dialog;
}

sub get_model_layout {
}

sub get_view_layout {
	my $available_views = shift;
		
	my @layout = (
		[
			[ 'Wx::StaticText', undef,               'View Name:' ],
			[ 'Wx::TextCtrl',   '_name_',            'TT'         ],
		],
		[
			[ 'Wx::StaticText', undef,              'Type'        ],
			[ 'Wx::Choice',     '_type_',       $available_views  ],
		],
		[
			[ 'Wx::CheckBox', '_force_', 'force', 0 ], #TODO add -mechanize parameter too
		],
		[
			[ 'Wx::Button',     '_ok_',           Wx::wxID_OK     ],
			[ 'Wx::Button',     '_cancel_',       Wx::wxID_CANCEL ],
		],
	);
	return \@layout;
}

sub get_controller_layout {
}


sub find_helpers_for {
	my $type = shift;
	
	require Module::Pluggable::Object;
	my @available_helpers = map { s{Catalyst::Helper::$type\:\:}{}; $_ 
						    } Module::Pluggable::Object->new(
									'search_path' => 'Catalyst::Helper::View',
							  )->plugins()
						;
	@available_helpers = sort @available_helpers;
	return \@available_helpers;
}

sub on_create_view {
	my $view_helpers = find_helpers_for('View');
    unless (scalar @{$view_helpers} > 0) {
    	my $main = Padre->ide->wx->main;
		Wx::MessageBox(
			'No helper views found.', 
			'Helper error', Wx::wxOK, $main
		);
		return;
	}
    my $layout = get_view_layout($view_helpers);
    
    my $dialog = dialog($layout, \&create_view);
    $dialog->Show(1);
    return;
}

# stub for now
sub on_create_controller {
}

# stub for now
sub on_create_model {
}

sub cancel_clicked {
	my $dialog = shift;
	$dialog->Destroy;
	return;
}

sub create_view {
	my $dialog = shift;
	my $data = $dialog->get_data;
	$dialog->Destroy;
	create('View', $data);
}

sub create_model {
}

sub create_controller {
}

sub create {
	my $type = shift;
	my $data = shift;
   	my $main = Padre->ide->wx->main;
   	
	unless ($data->{'_name_'}) {
		Wx::MessageBox(
			"You must provide a name for your $type module",
		'Module name required', Wx::wxOK, $main
		);
		return;
	}
   	
   	require Padre::Plugin::Catalyst::Util;
   	my $project_dir = Padre::Plugin::Catalyst::Util::get_document_base_dir();
					
   	my $helper_filename = Padre::Plugin::Catalyst::Util::get_catalyst_project_name($project_dir);
   	$helper_filename .= '_create.pl';

    my $helper_full_path = File::Spec->catfile($project_dir, 'script', $helper_filename );
    if(! -e $helper_full_path) {
        Wx::MessageBox(
            sprintf("Catalyst helper script not found at\n%s\n\nPlease make sure the active document is from your Catalyst project.", 
                    $helper_full_path
                   ),
            'Helper not found', Wx::wxOK, $main
        );
        return;
    }
   	
	# Prepare the output window for the output
	$main->show_output(1);
	$main->output->Remove( 0, $main->output->GetLastPosition );

    push my @cmd, 
				File::Spec->catfile('script', $helper_filename),
				lc $type,
			;
	
	# TODO: this should've been passed as a parameter
	# but I'm too tired to figure how to do it
	# under a Wx::Dialog (make it a global in last case)
	my $helper = find_helpers_for($type);
	
	push @cmd, 
			$data->{'_name_'},
			${$helper}[$data->{'_type_'}],
		;

	if ($data->{'_force_'}) {
		push @cmd, '-force';
	}

    $main->output->AppendText("running: @cmd\n");
	# go to the selected directory
	my $pwd = Cwd::cwd();
	chdir $project_dir;

	my $output_text = qx{@cmd};
	$main->output->AppendText($output_text);
	
	chdir $pwd; # restore directory

	$main->output->AppendText("\nCatalyst helper script ended.\n");
	
	my $ret = Wx::MessageBox(
		sprintf("%s apparently created. Do you want to open it now?", $type),
		'Done',
		Wx::wxYES_NO|Wx::wxCENTRE,
		$main,
	);
	if ( $ret == Wx::wxYES ) {
		my @dirs = File::Spec->splitdir($project_dir);
		my @parts = split /-/, $dirs[-1];

		my $file = File::Spec->catfile( $project_dir,
                                        'lib', 
                                        @parts,
                                        $type,
                                        $data->{'_name_'} . '.pm'
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