package Padre::Plugin::NYTProf;



use warnings;
use strict;


use base 'Padre::Plugin';


use Padre::Util   ('_T');

require Padre::Plugin::ProfilingTask;


our $VERSION = '0.01';

# Need to hold the nytprof variables
my %nytprofile;


# The plugin name to show in the Plugin Manager and menus
sub plugin_name { 'NYTProf' }

# Declare the Padre interfaces this plugin uses
sub padre_interfaces {
    'Padre::Plugin'         => 0.36,
#    'Padre::Document::Perl' => 0.16,
#    'Padre::Wx::Main'       => 0.16,
#    'Padre::DB'             => 0.16,
}


sub menu_plugins_simple {
    my $self = shift;
    return $self->plugin_name  => [
        
        _T('1. Run Profile')                               => sub { $self->on_start_profiling },
        _T('2. Generate Report - Run Profile First')           => sub { $self->on_generate_report },        
        _T('3. Show Report -     Run Generate Report First')           => sub { $self->on_show_report },
        
        '---'                                           => undef, # ...add a separator
        
        _T('About')             => sub { $self->on_show_about },
        
     ];
    
}

sub plugin_enable {
        return;
}

sub plugin_disable {
    require Class::Unload;
    Class::Unload->unload('Padre::Plugin::NYTProf');
#    Class::Unload->unload('Devel::NYTProf');

}


sub on_start_profiling {
    
    
    my $prof_task = Padre::Plugin::ProfilingTask->new;
    $prof_task->schedule;
    
#    my $main = Padre->ide->wx->main;
    
    # hash to hold environment variables
    # nytprof has a lot of options to set
    # once it clearer what we do or don't want
    # we can add sane defaults or set as we need
#    my %nytprof;

    # Environment hash.
    # $ENV{FOO} = 'bar'
    
    
    
#    my $tmp = File::Temp::tempdir;
#    my $nytprof_env_vars = '';
    
    #TODO: change this to be based on current document
#    my $nytprof_out = 'nytprof.out';
    
#    $nytprofile{file} = "$tmp/$nytprof_out";
        
#    my $perl = Padre->perl_interpreter;
    
    # Padre current document 
    # Padre->Current
    # ->document
    # ->filename
    
#    foreach my $env( keys %nytprofile ) {
#        $nytprof_env_vars .= "$env=$nytprofile{$env}:";
#    }
    
    # before we go any further save the temp directory location
    # into the hash here
#    $nytprofile{temp} = $tmp;
    
#    $nytprof_env_vars =~ s/\:$//;
#    $ENV{NYTPROF} = $nytprof_env_vars;
    
#    my $docPath = Padre::Current->document->filename; 
    
    # profile command    
#    my $profile = $perl . " -d:NYTProf $docPath";
    
#    print "Env: $nytprof_env_vars\n";
#    print "cmd: $profile\n";
    # run the profiling on the current document
#    $main->run_command($cmd);
    
#    sleep(10);
    
    

#    $main->run_command($profile);
    
#    return;
    
}
sub on_generate_report {
    
    my $main    = Padre->ide->wx->main;
    #my $tmp     =  File::Temp::tempdir;
    
    # create the commandline to create HTML output
    my $report = 'nytprofhtml ' . $nytprofile{file};
    print "Generating HTML report: $report\n";
    $main->run_command($report);
       
}

sub on_show_report {
        
    my $report = $nytprofile{temp} . '/nytprof/index.html';
    print "Loading report in browser: $report\n";
    
    Padre::Wx::launch_browser("file://$report");

    # testing..
    # now we need to read in the output file
    #require Devel::NYTProf::Data;
    my $profile = Devel::NYTProf::Data->new( { filename => $nytprofile{file} } );
    
    print $profile->dump_profile_data();

    
    return;
        
}

sub on_show_about {
    require Devel::NYTProf;
    require Class::Unload;
    my $about = Wx::AboutDialogInfo->new;
    $about->SetName("Padre::Plugin::NYTProf");
    $about->SetDescription(
		  "Initial NYTProf profile support for Padre\n\n"
		. "This system is running NYTProf version " . $Devel::NYTProf::VERSION . "\n"
	);
    $about->SetVersion( $VERSION );
    Class::Unload->unload('Devel::NYTProf');
    
    Wx::AboutBox( $about );
    return;
}


1;
__END__

=head1 NAME

Padre::Plugin::NYTProf - Integrated profiling for Padre.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Run profilng against your scripts from within Padre.

=head1 DESCRIPTION

The intention here is to have the profiler run over the current document and have it's report appear in a tab in the IDE.


=head1 AUTHOR

Peter Lavender, C<< <peter.lavender at gmail.com> >>

=head1 BUGS

Plenty I'm sure, but since this doesn't even load anything I'm fairly safe.


=head1 SUPPORT

#padre on irc.perl.org


=head1 ACKNOWLEDGEMENTS

I'd like to acknowledge the support and patience of the #padre channel.

With nothing more than bravado and ignorance I pulled this together with the help of those in the #padre
channel answering all my clearly lack of reading questions.

=head1 SEE ALSO

L<Catalyst>, L<Padre>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
