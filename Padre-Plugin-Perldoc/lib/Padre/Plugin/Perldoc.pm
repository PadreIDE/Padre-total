package Padre::Plugin::Perldoc;
use strict;
use warnings;
use 5.008;

our $VERSION = '0.01';

use Padre::Wx ();

use base 'Padre::Plugin';

=head1 NAME

Padre::Plugin::Perldoc - Perldoc interface using Pod::POM::Web

=head1 SYNOPSIS

After installation when you run Padre there should be a menu option Plugins/Perldoc
with several submenues.

About is just some short explanation

=head1 COPYRIGHT

Copyright 2008 Gabor Szabo. L<http://www.szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut


sub plugin_name {
	'Perldoc';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About'         => \&about,
		'Main'          => \&main,
	];
}

# start the web server?
sub plugin_enable {
	my $self = shift;
	
	my $pid;
	if ($^O eq 'linux') {
		my $p = "$^X /home/gabor/worl/padre/trunk/Padre-Plugin-Perldoc/pom_starter.pl &";
		my $cmd = qq{$^X -e 'print \$\$; system "$p"'};
		print "$cmd\n";
		$pid = qx{$cmd};
	} elsif ($^O eq 'MSWin32') {
	} else {
		warn "OS $^O not yet supported. Talk to the Padre developers\n";
	}

	return 1;
}



sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Perldoc");
	$about->SetDescription(
		"Perldoc interface using Pod::POM::Web\n"
	);
	$about->SetVersion($VERSION);
	Wx::AboutBox( $about );
	return;
}

sub main {
	Wx::LaunchDefaultBrowser('http://localhost:8080/');
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
