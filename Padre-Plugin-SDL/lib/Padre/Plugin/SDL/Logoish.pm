package Padre::Plugin::SDL::Logoish;

use 5.010;
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

=cut

use SDL::App;

# create a board optional named params:
# width, height
# ->new(width => 1000)
sub new {
	my ($class, %args) = @_;
	my $self = bless {}, $class;
	$self->{board}{width}  = $args{width}  || 640;
	$self->{board}{height} = $args{height} || 480;

	$self->{board}{app} = SDL::App->new(
		-width  => $self->{board}{width},
		-height => $self->{board}{height},
		-depth => 16, # TODO
		-title => 'SDL Padre Logoish', # TODO
	);

	# TODO pass color as param
	$self->{board}{bg_color} = SDL::Color->new(
		-r => 0x00,
		-g => 0x00,
		-b => 0x00,
		);

	$self->{board}{bg} = SDL::Rect->new(
		-width  => $self->{board}{width},
		-height => $self->{board}{height},
	);


	$self->{pen}{x}   = int($self->{board}{width}/2);
	$self->{pen}{y}   = int($self->{board}{height}/2);
	$self->{pen}{dir} = 'right';
	
	$self->set_pen_size_to(2);

	$self->{pen}{color} = SDL::Color->new(
		-r => 0x00,
		-g => 0x00,
		-b => 0xff,
        );
        
	$self->clear;
	
	return $self;
}

sub compile_to_perl5 {
	my ($class, $filename, $outfile) = @_;
	open my $fh,  '<', $filename or return "Could not open file ($filename) $!";
	open my $out, '>', $outfile or return "Could not open file ($outfile) $!";
	
	print $out <<'END_OUT';
use strict;
use warnings;

#use FindBin;
#use lib "$FindBin::Bin/../../lib";

use Padre::Plugin::SDL::Logoish;

my $logo = Padre::Plugin::SDL::Logoish->new;

#$event = SDL::Event->new;
#while ($event->poll) {
#	say "event";
#	my $type = $event->type;
#	exit if ($type == SDL_QUIT());
#	exit if ($type == SDL_KEYDOWN() && $event->key_name eq 'escape');
#}

	
END_OUT

	while (my $line = <$fh>) {
		chomp $line;
		#say $line;
		if ($line =~ /^\s*(#.*)?$/) {
			say $out $line;
			next;
		}
		if ($line =~ /^goto_xy\(  \s*(\d+)\s* , \s*(\d+)\s* \);$/x) {
			say $out "\$logo->goto_xy($1, $2);";
			next;
		}
		if ($line =~ /^sleep\( \s*(\d+)\s* \);$/x) {
			say $out "sleep($1);";
			next;
		}
		if ($line =~ /^clear\(\);$/x) {
			say $out "\$logo->clear();";
			next;
		}
		if ($line =~ /^set_pen_size_to\( \s*(\d+)\s* \);$/x) {
			say $out "\$logo->set_pen_size_to($1);";
			next;
		}
		return "Invalid line '$line' in line $.\n";
	}
	return;
}

=head2 Pen

=over 4

=item clear

clear background

=cut

sub clear {
	my $self = shift;
	$self->{board}{app}->fill( $self->{board}{bg}, $self->{board}{bg_color} );
}

=pod

=item pen_down TODO

The pen stays in the current location but from this point any movement
of the object will draw a line

=item pen_up TODO

The pen stays in the current location but moving around the object will
not leave any mark.


=item set_pen_color_to(rgb|color selector) TODO

Changes the color of the pen for further drawing to the given rgb value.
The visual display of this programming element includes a color selector.


=itme change_pen_color_by(number) TODO

TBD

=item set_pen_color_to(number) TODO

TBD

=item change_pen_shade_by(number) TODO

TBD

=item set_pen_shade_to(number) TODO

TBD

=item change_pen_size_by(number) TODO

=item stamp TODO
	
?

=item set_pen_size_to(number)


=cut

sub set_pen_size_to {
	my ($self, $size) = @_;
	
	$self->{pen}{size} = $size;

	if (not defined $self->{pen}{rect}) {
		$self->{pen}{rect} = SDL::Rect->new( 
			-height => $self->{pen}{size}, 
			-width  => $self->{pen}{size},
			);
	} else {
		$self->{pen}{rect}->width($size);
		$self->{pen}{rect}->height($size);
	}

	return;
}

=pod

=back

=head2 Motion

=over 4

=item *

	move (number) steps
	turn right (number) degrees
	turn left (number) degrees
	point in direction (number)
	point towards (???)

=item goto_xy(number, number)

=cut 

sub goto_xy {
	my ($self, $to_x, $to_y) = @_;

	# just put something at (x, y);
	#$self->{pen}{rect}->x($to_x);
	#$self->{pen}{rect}->y($to_y);
	#$self->{board}{app}->fill( $self->{pen}{rect}, $self->{pen}{color} );
	#$self->{board}{app}->update( $self->{board}{bg} );
	#return;
	
	my %to = (x => $to_x, y => $to_y);
	
	return if $to{x} == $self->{pen}{x} and $to{y} == $self->{pen}{y};
	
	my %diff = (
		x => abs($self->{pen}{x} - $to{x}),
		y => abs($self->{pen}{y} - $to{y}),
	);
	my ($lead, $follow) = $diff{y} > $diff{x} ? ('y', 'x') : ('x', 'y');
	#print "lead: $lead, follow: $follow\n";
	#print "from ($self->{pen}{x}, $self->{pen}{y}) to ($to{x}, $to{y})\n";

	# draw a recangualar?
	# what if the change in x is smaller than the change in y (or even 0)

	my %dir = (
		$lead   => $self->{pen}{$lead} < $to{$lead} ? 1 : -1,
		$follow => $self->{pen}{$follow} < $to{$follow} ? 1 : -1,
	);
	for my $lead_coord (0 .. $diff{$lead}) {
		$self->{pen}{rect}->$lead( $self->{pen}{$lead} + $dir{$lead} * $lead_coord );
		my $follow_coord = $lead_coord * $diff{$follow}/$diff{$lead};
		$self->{pen}{rect}->$follow( $self->{pen}{$follow} + $dir{$lead} * $follow_coord );
		$self->{board}{app}->fill( $self->{pen}{rect}, $self->{pen}{color} );
		$self->{board}{app}->update( $self->{board}{bg} );
	}

	$self->{pen}{x} = $to{x};
	$self->{pen}{y} = $to{y};

	return;
}

=pod

=item *

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

=back


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

1;

