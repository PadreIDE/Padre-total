package Padre::Plugin::Catalyst::Helper;

use 5.008;
use strict;
use warnings;
use Cwd               ();
use File::Spec        ();
use Padre::Wx         ();
use Padre::Wx::Dialog ();

our $VERSION = '0.02';

# TODO: these should've been passed as a parameter
# but I'm too tired to figure how to do it
# under a Wx::Dialog 
my $helpers_for = {
		'view'       => [],
		'model'      => [],
		'controller' => [],
};

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
	my $available_models 
		= $helpers_for->{'models'}; #shift; TODO: ungloball this
		
	my @layout = (
		[
			[ 'Wx::StaticText', undef,                    'Model Name:' ],
			[ 'Wx::TextCtrl',   '_name_',                 ''            ],
		],
		[
			[ 'Wx::StaticText', undef,                         'Type'   ],
			[ 'Wx::Choice',     '_type_',            $available_models  ],
		],
		[
			[ 'Wx::StaticText', undef           ,   'Additional Parameters:' ],
			[ 'Wx::TextCtrl'  , '_extra_params_',   ''                       ],
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

sub get_view_layout {
	my $available_views = $helpers_for->{'view'}; #shift; TODO: ungloball this
		
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
	my $available_controllers 
		= $helpers_for->{'controller'}; #shift; TODO: ungloball this
		
	my @layout = (
		[
			[ 'Wx::StaticText', undef,                    'Controller Name:' ],
			[ 'Wx::TextCtrl',   '_name_',                 ''                 ],
		],
		[
			[ 'Wx::StaticText', undef,                         'Type'        ],
			[ 'Wx::Choice',     '_type_',            $available_controllers  ],
		],
		[
			[ 'Wx::StaticText', undef           ,   'Additional Parameters:' ],
			[ 'Wx::TextCtrl'  , '_extra_params_',   ''                       ],
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


sub find_helpers_for {
	my $type = shift;
	
	require Module::Pluggable::Object;
	my @available_helpers = map { s{Catalyst::Helper::$type\:\:}{}; $_ 
						    } Module::Pluggable::Object->new(
									'search_path' => "Catalyst::Helper::$type",
							  )->plugins()
						;
	push @available_helpers, '[none]';
	
	## Put preferred types first on the list. For example, 
	# as a view, TT is preferred.
	# TODO: make this configurable under a Plugin Preferences window
	my $favourite = find_favourites($type, \@available_helpers);
	
	# puts favourite option always on top of the list
	@available_helpers = (
			$favourite,
			grep {$_ ne $favourite} sort @available_helpers
	);
	return \@available_helpers;
}

sub find_favourites {
	my $type = shift;
	my $helpers = shift;
	if ($type eq 'View') {
		foreach (@{$helpers}) {
			return $_ if ($_ eq 'TT');
		}
		return '[none]';
	}
	else {
		return '[none]';
	}
}


sub on_create_view {
	$helpers_for->{'view'} = find_helpers_for('View'); # TODO: unglobal this
	my $layout = get_view_layout();
	my $dialog = dialog($layout, \&create_view);
	$dialog->Show(1);
	return;
}


sub on_create_controller {
	$helpers_for->{'controller'} = find_helpers_for('Controller'); # TODO: unglobal this
	my $layout = get_controller_layout();
	my $dialog = dialog($layout, \&create_controller);
	$dialog->Show(1);
	return;
}


sub on_create_model {
	$helpers_for->{'model'} = find_helpers_for('Model'); # TODO: unglobal this
	my $layout = get_model_layout();
	my $dialog = dialog($layout, \&create_model);
	$dialog->Show(1);
	return;
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
	my $dialog = shift;
	my $data = $dialog->get_data;
	$dialog->Destroy;
	create('Model', $data);
}

sub create_controller {
	my $dialog = shift;
	my $data = $dialog->get_data;
	$dialog->Destroy;
	create('Controller', $data);
}


sub create {
	my $type = lc(shift);
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

    my $perl = Padre->perl_interpreter;
    push my @cmd, 
				$perl,
				File::Spec->catfile('script', $helper_filename),
				$type,
			;
	
	my $helper = $helpers_for->{$type}; #TODO: unglobal this
	push @cmd, 
			$data->{'_name_'},
			( ${$helper}[$data->{'_type_'}] eq '[none]' 
			  ? '' 
			  : ${$helper}[$data->{'_type_'}] 
			),
			( defined $data->{'_extra_params_'}
			  ? $data->{'_extra_params_'}
			  : ''
			),
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

	require Padre::Plugin::Catalyst::Util;
	my $file = Padre::Plugin::Catalyst::Util::find_file_from_output(
					$data->{'_name_'}, 
					$output_text
			   );
	if ($file) {
		my $ret = Wx::MessageBox(
			sprintf("%s apparently created. Do you want to open it now?", $type),
			'Done',
			Wx::wxYES_NO|Wx::wxCENTRE,
			$main,
		);
		if ( $ret == Wx::wxYES ) {
			Padre::DB::History->create(
				type => 'files',
				name => $file,
			);
			$main->setup_editor($file);
			$main->refresh;
		}
	}
	return;
}

42;