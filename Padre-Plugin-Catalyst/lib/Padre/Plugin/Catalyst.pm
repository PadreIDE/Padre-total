package Padre::Plugin::Catalyst;
use base 'Padre::Plugin';

use warnings;
use strict;

our $VERSION = '0.01';

# The plugin name to show in the Plugin Manager and menus
sub plugin_name {
    'Catalyst';
}
  
# Declare the Padre interfaces this plugin uses
sub padre_interfaces {
    'Padre::Plugin'         => 0.29,
#    'Padre::Document::Perl' => 0.16,
#    'Padre::Wx::Main'       => 0.16,
#    'Padre::DB'             => 0.16,
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
                'Model'      => sub { $self->on_create_model      },
                'View'       => sub { $self->on_create_view       },
                'Controller' => sub { $self->on_create_controller },
            ],
            'Start Web Server' => sub { $self->on_start_server },
            'Stop Web Server'  => sub { $self->on_stop_server  },
            '---'     => undef, # separator
            'About'   => sub { $self->on_show_about },
    ];
}

sub get_document_base_dir {	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	my $filename = $doc->filename;
	return Padre::Util::get_project_dir($filename);
}

sub create {
    my ($type, $basedir) = (@_);
   	my $main = Padre->ide->wx->main;
   	
   	# TODO: find $project_name ?
   	# TODO: CWD to the correct dir?
   	
   	require File::Spec;
#   	File::Spec->catfile('script', $project_name . '_create.pl');
    my $cmd = File::Spec->catfile($basedir);
	my $status = qx{ls $cmd};
	$main->message($status, "$cmd");
	return;
}

sub on_create_model {
    my $dir = get_document_base_dir();
    create('model', $dir);
}

sub on_create_view {
}

sub on_create_controller {
}

sub on_start_server {
    my $project_dir = get_document_base_dir();
    print STDERR "doc base dir is $project_dir\n";
    my $main = Padre->ide->wx->main;
    
    # get the Catalyst project name, so we can
    # figure out the development server's name
    # TODO: make this code suck less
    require File::Spec;
    my @dirs = File::Spec->splitdir($project_dir);
    my $server_filename = lc($dirs[-1]);
    $server_filename =~ tr{-}{_};
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

    $main->run_command(File::Spec->catfile('script', $server_filename));
    
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
        $main->{command}->TerminateProcess;
    }
    delete $main->{command};
    $main->menu->run->enable;
    $main->output->AppendText("\nWeb server stopped successfully.\n");
    return;
}

sub on_show_about {
    my $self = shift;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Catalyst");
	$about->SetDescription("Initial Catalyst support for Padre");
	$about->SetVersion( $VERSION );

	Wx::AboutBox( $about );
	return;
}

sub plugin_disable {
    require Class::Unload;
    Class::Unload->unload('Padre::Plugin::Catalyst::NewApp');
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


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
