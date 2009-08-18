package Padre::Plugin::SDL;

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();
use Padre::Util   ();

use File::Temp     qw(tempdir);
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile);

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';

=head1 NAME

Padre::Plugin::SDL - Simple SDL helper for Padre

=head1 SYNOPSIS

cpan install Padre::Plugin::SDL

Read the documentation of L<SDL>, 
L<SDL::App>, L<SDL::Surface>, L<SDL::Event> and L<SDL::Constants>.


=head1 AUTHOR

Gabor Szabo, C<< <szabgab at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

#####################################################################
# Padre::Plugin Methods

sub padre_interfaces {
	'Padre::Plugin' => 0.42;
}

sub plugin_name {
	'SDL';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About'          => sub { $self->show_about },
		'Tutorial'       => sub { Padre->ide->wx->main->help('SDL::Tutorial') },
		'Logoish docs'   => sub { Padre->ide->wx->main->help('Padre::Plugin::SDL::Logoish') },
		'Run in Logoish' => \&run_in_logoish,

	];
}

#####################################################################
# Custom Methods


sub run_in_logoish {
	my $main = Padre->ide->wx->main;
	my $doc = Padre::Current->document;

	if (not $doc) {
		$main->error("No document is available");
		return;
	}
	
	my $filename = $doc->filename;
	if (not $filename) {
		$main->error("File needs to be saved (no filename found)");
		return;
	}

	# save current file
	$main->on_save;

	my $result = _run($filename);
	if ($result) {
		$main->error($result);
		return;
	}
	return;
}

# temporary name of the method that will 
#    read the file
#    parse it, make sure it is correct script
#    compile it to real perl code and execute it
sub _run {
	my ($filename) = @_;

	require Padre::Plugin::SDL::Logoish;

	my $dir = tempdir(CLAENUP => 0);

	my $out_filename = catfile($dir, basename($filename));
	my $error = Padre::Plugin::SDL::Logoish->compile_to_perl5($filename, $out_filename);
	return $error if $error;

	# run script
	my $perl = Padre::Perl::perl();
	my $cmd = "$perl $out_filename";
	my $main = Padre->ide->wx->main;
	$main->run_command($cmd);
	return;
}



sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::SDL");
	$about->SetDescription( <<"END_MESSAGE" );
Initial SDL support for Padre
END_MESSAGE
	$about->SetVersion($VERSION);

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

1;

