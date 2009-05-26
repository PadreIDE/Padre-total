package Padre::Plugin::Mojolicious;
use base 'Padre::Plugin';

use warnings;
use strict;

use Padre::Util   ('_T');

our $VERSION = '0.02';

# The plugin name to show in the Plugin Manager and menus
sub plugin_name { 'Mojolicious' }
  
# Declare the Padre interfaces this plugin uses
sub padre_interfaces {
    'Padre::Plugin'         => 0.29,
#    'Padre::Document::Perl' => 0.16,
#    'Padre::Wx::Main'       => 0.16,
#    'Padre::DB'             => 0.16,
}

sub plugin_icon {
	my $icon = [
		'16 16 27 1'   , ' 	c None'    , '.	c #4082AE' , '+	c #3F81AC' , '@	c #3D7EA9' ,
	    '#	c #3C7DA8' , '$	c #37759D' , '%	c #255A7B' , '&	c #25587A' , '*	c #3F81AD' ,
		'=	c #3977A0' , '-	c #275C7E' , ';	c #245879' , '>	c #235576' , ',	c #3E7FAA' ,
		'\'	c #235677' , ')	c #225474' , '!	c #3F80AC' , '~	c #245779' , '{	c #3B7AA5' ,
		']	c #36729A' , '^	c #36739C' , '/	c #306A8F' , '(	c #306A90' , '_	c #2B6285' ,
		':	c #2B6185' , '<	c #265A7B' , '[	c #25597B' , '                ' , '                ',
		'                ', '                ' , '  .. ...  ...   ', '  ..+...@#...+  ',
		'  ..$%&*.=-;**> ', '  .,\') .!~) .{) ', '  .])  .^)  .]) ', ' ../) ..() ../) ',
		' .._  ..:  ..:  ', ' ..<  ..[  ..[  ' , '  ))   ))   ))  ', '                ',
		'                ', '                ',
	];

	return Wx::Bitmap->newFromXPM( $icon );
}

# The command structure to show in the Plugins menu
sub menu_plugins_simple {
    my $self = shift;
    
    return $self->plugin_name  => [
            _T('New Mojolicious Application') => sub { 
                                require Padre::Plugin::Mojolicious::NewApp;
                                Padre::Plugin::Mojolicious::NewApp::on_newapp();
                                return;
                            },
			'---'     => undef, # separator
            _T('Start Web Server') => sub { $self->on_start_server },
            _T('Stop Web Server')  => sub { $self->on_stop_server  },
            '---'     => undef, # ...and another separator
            _T('Mojolicious Online References') => [
				_T('Mojolicious Manual') => sub {
					Wx::LaunchDefaultBrowser('http://search.cpan.org/perldoc?Mojo::Manual::Mojolicious');
				},
				_T('Mojolicious Website') => sub {
					Wx::LaunchDefaultBrowser('http://www.mojolicious.org/');
				},
            ],
            '---'         => undef, # ...oh
            _T('About')   => sub { $self->on_show_about },
    ];
}


sub on_start_server {
    my $main = Padre->ide->wx->main;

    require Padre::Plugin::Mojolicious::Util;
    my $project_dir = Padre::Plugin::Mojolicious::Util::get_document_base_dir();

    my $server_filename = Padre::Plugin::Mojolicious::Util::get_mojolicious_project_name($project_dir);

    my $server_full_path = File::Spec->catfile($project_dir, 'bin', $server_filename );
    if(! -e $server_full_path) {
        Wx::MessageBox(
            sprintf(_T("Mojolicious application script not found at\n%s\n\nPlease make sure the active document is from your Mojolicious project."), 
                    $server_full_path
                   ),
            _T('Server not found'), Wx::wxOK, $main
        );
        return;
    }
    
    # go to the selected file's directory
    # (Mojolicious instructs us to always run their scripts
    #  from the basedir)
	my $pwd = Cwd::cwd();
	chdir $project_dir;

    my $perl = Padre->perl_interpreter;
    my $command = "$perl " . File::Spec->catfile('bin', $server_filename) 
                           . ' daemon';
                           
    $main->run_command($command);
    
    # restore current dir
    chdir $pwd;
    
    # TODO: actually check whether this is true.
    my $ret = Wx::MessageBox(
		_T('Web server appears to be running. Launch web browser now?'),
		_T('Start Web Browser?'),
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
	$main->output->AppendText(_T("\nWeb server stopped successfully.\n"));
	return;
}

sub on_show_about {
	require Mojo;
	require Class::Unload;
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Mojolicious");
	$about->SetDescription(
		  "Initial Mojolicious support for Padre\n\n"
		. "This system is running Mojolicious version " . $Mojo::VERSION . "\n"
	);
	$about->SetVersion( $VERSION );
	Class::Unload->unload('Mojo');

	Wx::AboutBox( $about );
	return;
}

sub plugin_disable {
    require Class::Unload;
    Class::Unload->unload('Padre::Plugin::Mojolicious::NewApp');
    Class::Unload->unload('Padre::Plugin::Mojolicious::Util');
    Class::Unload->unload('Mojo');
}

42;
__END__
=head1 NAME

Padre::Plugin::Mojolicious - Simple Mojolicious helper interface for Padre

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

B<WARNING: CODE IN PROGRESS>

	cpan install Padre::Plugin::Mojolicious;

Then use it via L<Padre>, The Perl IDE.

=head1 DESCRIPTION

Once you enable this Plugin under Padre, you'll get a brand new menu with the following options:

=head2 'New Mojolicious Application'

This options lets you create a new Mojolicious application.

=head2 'Start Web Server'

This option will automatically spawn your application's development web server. Once it's started, it will ask to open your default web browser to view your application running.

Note that this works like Padre's "run" menu option, so any other execution it will be disabled while your server is running.

=head2 'Stop Web Server'

This option will stop the development web server for you.

=head2 'Mojolicious Online References'

This menu option contains a series of external reference links on Mojolicious. Clicking on each of them will point your default web browser to their websites.

=head2 'About'

Shows a nice about box with this module's name and version.


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-padre-plugin-mojolicious at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Mojolicious>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Padre::Plugin::Mojolicious


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Mojolicious>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Mojolicious>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Mojolicious>

=item * Search CPAN

L<http://search.cpan.org/dist/Padre-Plugin-Mojolicious/>

=back


=head1 SEE ALSO

L<Mojolicious>, L<Padre>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
