package Padre::Plugin::CPAN;

use warnings;
use strict;

our $VERSION = '0.07';

use base 'Padre::Plugin';
use Wx ':everything';
use File::Spec ();

sub padre_interfaces {
	'Padre::Plugin' => '0.21',
}

sub menu_plugins_simple {
	'CPAN' => [
		'Edit Config',    \&edit_config,
		'Install Module', \&install_module,
		'Upgrade All Padre Plugins', \&upgrade_all_plugins,
	];
}

sub edit_config {
	my ( $self ) = @_;
	
	# get the place of the CPAN::Config;
	require CPAN;
	my $default_dir = $INC{'CPAN.pm'};
	$default_dir =~ s/\.pm$//is; # remove .pm
	my $filename = 'Config.pm';
	
	# copy from MainWindow.pm sub on_open
	
	my $file = File::Spec->catfile($default_dir, $filename);
	Padre::DB->add_recent_files($file);

	# If and only if there is only one current file,
	# and it is unused, close it.
	if ( $self->{notebook}->GetPageCount == 1 ) {
		if ( Padre::Documents->current->is_unused ) {
			$self->on_close($self);
		}
	}

	$self->setup_editor($file);
	$self->refresh_all;
}

sub install_module {
	my ( $self ) = @_;
	
	require Padre::Wx::History::TextDialog;
	my $dialog = Padre::Wx::History::TextDialog->new(
        $self, "Module name(s):\neg: CPAN Padre", 'Install Module', 'CPAN_INSTALL_MODULE',
    );
    if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
        return;
    }
    my $module_name = $dialog->GetValue;
    $dialog->Destroy;
    unless ( defined $module_name ) {
        return;
    }
    
    # YYY? do some validate here?
    
    _run_cpan_command( $self, $module_name);
}

sub upgrade_all_plugins {
	my ( $self ) = @_;
	
	my @modules;
	my %plugins = %{ Padre->ide->plugin_manager->plugins };
    foreach my $name ( keys %plugins ) {
		next if ( $name eq 'Parrot' ); # it's in Padre core
		push @modules, "'Padre::Plugin::$name'";
    }

	my $modules = join(', ', @modules);
    _run_cpan_command( $self, $modules );
}

sub _run_cpan_command {
	my ( $self, $modules ) = @_;

	# Copied from Padre/Wx/MainWindow.pm sub run_command
    
    # If this is the first time a command has been run,
	# set up the ProcessStream bindings.
	unless ( $Wx::Perl::ProcessStream::VERSION ) {
		require Wx::Perl::ProcessStream;
		Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_STDOUT(
			$self,
			sub {
				$_[1]->Skip(1);
				$_[0]->{gui}->{output_panel}->AppendText( $_[1]->GetLine . "\n" );
				return;
			},
		);
		Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_STDERR(
			$self,
			sub {
				$_[1]->Skip(1);
				$_[0]->{gui}->{output_panel}->AppendText( $_[1]->GetLine . "\n" );
				return;
			},
		);
		Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_EXIT(
			$self,
			sub {
				$_[1]->Skip(1);
				$_[1]->GetProcess->Destroy;

				$self->{menu}->enable_run;
			},
		);
	}
    
    # Run with the same Perl that launched Padre
	# TODO: get preferred Perl from configuration
	my $perl = Padre->perl_interpreter;
    
    $self->show_output(1);
	$self->{gui}->{output_panel}->clear;;
	
	# save original $ENV{AUTOMATED_TESTING}
	my $org_AUTOMATED_TESTING = $ENV{AUTOMATED_TESTING};
	$ENV{AUTOMATED_TESTING} = 1;
	
	my $cmd = qq{"$perl" "-MCPAN" "-e" "install $modules"};
	warn "run $cmd\n";
	Wx::Perl::ProcessStream->OpenProcess( $cmd, 'CPAN_mod', $self );
	
	# restore
	$ENV{AUTOMATED_TESTING} = $org_AUTOMATED_TESTING;
}

1;
__END__

=head1 NAME

Padre::Plugin::CPAN - CPAN in Padre

=head1 SYNOPSIS

	$>padre
	Plugins -> CPAN -> *

=head1 DESCRIPTION

CPAN in Padre

=head2 Edit Config

Edit CPAN/Config.pm

=head2 Install Module

run cpan $mod inside Padre. behave likes:

	perl -MCPAN -e "install $mod"

=head2 Upgrade All Padre Plugins

upgrade all plugin in one hit

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
