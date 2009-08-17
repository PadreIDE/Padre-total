package Padre::Plugin::SDL::Logoish;

use 5.008;
use warnings;
use strict;

our $VERSION = '0.01';

=head1 NAME

Padre::Plugin::SDL::Logoish - An experimental LOGO like langauge based on SDL Perl

=head1 SYNOPSIS

The user should be able to write a script with a simlified language we create.

=head1 DESCRIPTION

As I am planning to implement something similar to Scratch let me write down
the currently available methods in some of the groups of Scratch 1.4

=head2 Pen

	Clear
	pen down
	pen up
	set pen color to (color selector)
	change pen color by (number)
	set pen color to (number)
	change pen shade by (number)
	set pen shade to (number)
	change pen size by (number)
	set pen size to (number)
	stamp

=head2 Motion

	move (number) steps
	turn right (number) degrees
	turn left (number) degrees
	point in direction (number)
	point towards (???)
	go to x: (number) y: (number)
	go to (???)
	glide (number) secs to x: (number) y: (number)
	change x by (number)
	set x to (number)
	change y by (number)
	set y to (number)
	if on edge, bounce

	the value of x position
	the value of y position
	the value of the direction   (in degrees)



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
		'About'     => sub { $self->show_about },
		'Tutorial'  => sub { Padre->ide->wx->main->help('SDL::Tutorial') },
	];
}

#####################################################################
# Custom Methods

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

