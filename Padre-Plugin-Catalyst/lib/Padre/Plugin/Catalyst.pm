package Padre::Plugin::Catalyst;
use base 'Padre::Plugin';

use warnings;
use strict;

our $VERSION = '0.02';

# The plugin name to show in the Plugin Manager and menus
sub plugin_name { 'Catalyst' }
  
# Declare the Padre interfaces this plugin uses
sub padre_interfaces {
    'Padre::Plugin'         => 0.29,
#    'Padre::Document::Perl' => 0.16,
#    'Padre::Wx::Main'       => 0.16,
#    'Padre::DB'             => 0.16,
}

sub plugin_icon {
	my $icon = [ 
		'16 16 46 1'   , '   c None'   , '.  c #D15C5C', '+  c #E88888', '@  c #E10000',
		'#  c #D03131' , '$  c #D26262', '%  c #D26161', '&  c #E99F9F', '*  c #EFACAC',
		'=  c #EFADAD' , '-  c #E79090', ';  c #D14949', '>  c #D22727', ',  c #E26666',
		'\'  c #E26363', ')  c #E26464', '!  c #D42A2A', '~  c #D40101', '{  c #D50B0B',
		']  c #D71313' , '^  c #D50C0C', '/  c #D40404', '(  c #D26767', '_  c #DF5353',
		':  c #E15B5B' , '<  c #D95D5D', '[  c #D21313', '}  c #D30000', '|  c #DA0000',
		'1  c #D90000' , '2  c #D31111', '3  c #D14646', '4  c #DC1313', '5  c #EC0000',
		'6  c #E20000' , '7  c #F00000', '8  c #F20000', '9  c #D33232', '0  c #D64646',
		'a  c #D46969' , 'b  c #D35555', 'c  c #D23A3A', 'd  c #E89090', 'e  c #E98E8E',
		'f  c #D60000' , 'g  c #D70101', '                ', '            .   ',
		'            +   ', '            @#  ', '                '  , '                ',
		'        $%      ', '       &*=-;    ', '      >,\'\')!    ', '      ~{]]^/    ',
		'(_: < [}|1}2    ', '345    67869    ', ' 0a         b c ', '              de'  ,
		'              fg', '                ',
	];
	return Wx::Bitmap->newFromXPM( $icon );
}

# The command structure to show in the Plugins menu
sub menu_plugins_simple {
    my $self = shift;
    
    return $self->plugin_name  => [
            'New Catalyst Application' => sub { 
                                require Padre::Plugin::Catalyst::NewApp;
                                Padre::Plugin::Catalyst::NewApp::on_newapp();
                                return;
                            },
            'Create new...' => [
                'Model'      => sub { 
								require Padre::Plugin::Catalyst::Helper;
								Padre::Plugin::Catalyst::Helper::on_create_model();
							},
                'View'       => sub { 
								require Padre::Plugin::Catalyst::Helper;
								Padre::Plugin::Catalyst::Helper::on_create_view();
							},
                'Controller' => sub {
								require Padre::Plugin::Catalyst::Helper;
								Padre::Plugin::Catalyst::Helper::on_create_controller();
							},
            ],
			'---'     => undef, # separator
            'Start Web Server' => sub { $self->on_start_server },
            'Stop Web Server'  => sub { $self->on_stop_server  },
            '---'     => undef, # ...and another separator
            'Catalyst Online References' => [
				'Beginner\'s Tutorial' => sub { 
					Wx::LaunchDefaultBrowser('http://search.cpan.org/perldoc?Catalyst::Manual::Tutorial');
				},
				'Catalyst Cookbook' => sub {
					Wx::LaunchDefaultBrowser('http://search.cpan.org/perldoc?Catalyst::Manual::Cookbook');
				},
				'Recommended Plugins' => sub {
					Wx::LaunchDefaultBrowser('http://dev.catalystframework.org/wiki/recommended_plugins');
				},
				'Examples' => sub {
					Wx::LaunchDefaultBrowser('http://dev.catalyst.perl.org/repos/Catalyst/trunk/examples/');
				},
				'Catalyst Wiki' => sub {
					Wx::LaunchDefaultBrowser('http://dev.catalystframework.org/wiki/');
				},
				'Catalyst Website' => sub {
					Wx::LaunchDefaultBrowser('http://www.catalystframework.org/');
				},
            ],
            '---'     => undef, # ...oh
            'About'   => sub { $self->on_show_about },
    ];
}


sub on_start_server {
    my $main = Padre->ide->wx->main;

	require Padre::Plugin::Catalyst::Util;
    my $project_dir = Padre::Plugin::Catalyst::Util::get_document_base_dir();

	my $server_filename = Padre::Plugin::Catalyst::Util::get_catalyst_project_name($project_dir);
						
    $server_filename .= '_server.pl';
    
    my $server_full_path = File::Spec->catfile($project_dir, 'script', $server_filename );
    if(! -e $server_full_path) {
        Wx::MessageBox(
            sprintf("Catalyst development web server not found at\n%s\n\nPlease make sure the active document is from your Catalyst project.", 
                    $server_full_path
                   ),
            'Server not found', Wx::wxOK, $main
        );
        return;
    }
    
    # go to the selected file's directory
    # (catalyst instructs us to always run their scripts
    #  from the basedir)
	my $pwd = Cwd::cwd();
	chdir $project_dir;

    my $perl = Padre->perl_interpreter;
    my $command = "$perl " . File::Spec->catfile('script', $server_filename);
    $main->run_command($command);
    
    # restore current dir
    chdir $pwd;
    
    # TODO: actually check whether this is true.
    my $ret = Wx::MessageBox(
		'Web server appears to be running. Launch web browser now?',
		'Start Web Browser?',
		Wx::wxYES_NO|Wx::wxCENTRE,
		$main,
	);
	if ( $ret == Wx::wxYES ) {
        Wx::LaunchDefaultBrowser('http://localhost:3000');
    }
    
    #TODO: handle menu greying
    
    return;
}

sub on_stop_server {
	# TODO: Make this actually call
	# Run -> Stop
	my $main = Padre->ide->wx->main;
	if ( $main->{command} ) {
		my $processid = $main->{command}->GetProcessId();
		kill(9, $processid);
		#$main->{command}->TerminateProcess;
	}
	delete $main->{command};
	$main->menu->run->enable;
	$main->output->AppendText("\nWeb server stopped successfully.\n");
	return;
}

sub on_show_about {
	require Catalyst;
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Catalyst");
	$about->SetDescription(
		  "Initial Catalyst support for Padre\n\n"
		. "This system is running Catalyst version " . $Catalyst::VERSION . "\n"
	);
	$about->SetVersion( $VERSION );

	Wx::AboutBox( $about );
	return;
}

sub plugin_disable {
    require Class::Unload;
    Class::Unload->unload('Padre::Plugin::Catalyst::NewApp');
    Class::Unload->unload('Padre::Plugin::Catalyst::Helper');
    Class::Unload->unload('Padre::Plugin::Catalyst::Util');
    Class::Unload->unload('Catalyst');
}

42;
__END__
=head1 NAME

Padre::Plugin::Catalyst - Simple Catalyst helper interface for Padre

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

B<WARNING: CODE IN PROGRESS>

	cpan install Padre::Plugin::Catalyst;

Then use it via L<Padre>, The Perl IDE.

=head1 DESCRIPTION

Once you enable this Plugin under Padre, you'll get a brand new menu with the following options:

=head2 'New Catalyst Application'

=head2 'Create new...'

=head3 'Model'

=head3 'View'

=head3 'Controller'

=head2 'Start Web Server'

=head2 'Stop Web Server'

=head2 'About'

Shows a nice about box with this module's name and version.

=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-padre-plugin-catalyst at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Catalyst>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Padre::Plugin::Catalyst


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Catalyst>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Catalyst>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Catalyst>

=item * Search CPAN

L<http://search.cpan.org/dist/Padre-Plugin-Catalyst/>

=back


=head1 SEE ALSO

L<Catalyst>, L<Padre>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
