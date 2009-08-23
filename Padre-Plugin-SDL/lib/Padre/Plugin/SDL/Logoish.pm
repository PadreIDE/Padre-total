package Padre::Plugin::SDL::Logoish;

use 5.010;
use warnings;
use strict;

our $VERSION = '0.01';

=head1 NAME

Padre::Plugin::SDL::Logoish - An experimental LOGO like language based on SDL Perl

=head1 SYNOPSIS

The user should be able to write a script with a simlified language we create.

=head1 PLANS

The long term project goal is to provide a visual programming environment
for both children, and grown up professional non-programmers. Bt the latter 
I mean people who need to do some manipulations with computers but whom
are not programmers

I am planning to implement something similar to Scratch L<http://scratch.mit.edu/>
and Yahoo Pipes L<http://pipes.yahoo.com/pipes/> but I am also planning to
take ideas from LEGO Mindstorms L<http://mindstorms.lego.com/> and
Sprog L<http://sprog.sourceforge.net/>.

See also L<http://howto.wired.com/wiki/Teach_a_Kid_to_Program>

The first step is to re-implement some of the programatic features of Scratch such as
drawing on a board, moving a sprite around on the the board.

Once the basics are implemented we need to implement the drag-and-drop programming for
the already implemented language.

Then we can start to think on some challenges to give to the users. I can imagine some kind
of step-by-step process where the user starts with very few capabilities and simple tasks
to achive using those tools. Then as she progresses she gets more tools (programming elements)
and harder challenges.

=head1 DESCRIPTION


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
	$self->{pen}{dir} = 0;
	
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
		# special
		if ($line =~ /^wait\( \s*(\d+)\s* \);$/x) {
			say $out "\$logo->wait($1);";
			next;
		}

		# no param
		if ($line =~ /^(the_value_of_the_direction|the_value_of_x_position|the_value_of_y_position|clear)\(\);$/x) {
			say $out "\$logo->$1();";
			next;
		}
		# one number
		if ($line =~ /^set_pen_size_to\( \s*(\d+)\s* \);$/x) {
			say $out "\$logo->set_pen_size_to($1);";
			next;
		}
		# one possibly negative number
		if ($line =~ /^change_pen_size_by\( \s*(-?\d+)\s* \);$/x) {
			say $out "\$logo->change_pen_size_by($1);";
			next;
		}
		# two numbers
		if ($line =~ /^goto_xy\(  \s*(\d+)\s* , \s*(\d+)\s* \);$/x) {
			say $out "\$logo->goto_xy($1, $2);";
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

=item change_pen_size_by(number)

The number can be either positive or negative integer.
Change the size of the pen by that number. Effects any new  drawings.

=cut

sub change_pen_size_by {
	my ($self, $number) = @_;
	my $new_size = $self->{pen}{size} + $number;
	if ($new_size <= 0) {
		# TODO error handling?
		return;
	}
	$self->set_pen_size_to($new_size);
}

=item stamp TODO
	
?

=item set_pen_size_to(number)

Set the width and the height of the pen to the given number (in pixels).

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

=item move(number) TODO

move number of steps (?)

=item turn_right(number) TODO

Turn the object to the right (clock-wise) by given number of degrees.
No other movement is visible.

=item turn_left(number) TODO

Turn the object to the left (ant-clock-wise) by given number of degrees.
No other movement is visible.

=item point_in_direction(number) TODO

Set the direction to the given number in degrees.
0 is up, 90 is right on the screen.

=item point_towards(???) TODO

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

=item goto(???) TODO

=item glide (number) secs to x: (number) y: (number) TODO

=item change x by (number) TODO

=item set x to (number) TODO

=item change y by (number) TODO

=item set y to (number) TODO

=item if on edge, bounce TODO

=item the_value_of_x_position

returns the value of x. (getter)

=cut

sub the_value_of_x_position {
	my ($self) = @_;
	return $self->{pen}{x};
}

=item the_value_of_y_position

Returns the value of y. (getter)

=cut

sub the_value_of_y_position {
	my ($self) = @_;
	return $self->{pen}{y};
}

=item the_value_of_the_direction

Returns the value of the direction in degrees. (getter)

=cut

sub the_value_of_the_direction {
	my ($self) = @_;
	return $self->{pen}{dir};
}	

=pod

=back


=head2 Events

In Scratch these events are under the Controls catgory.
They all have a hump on the top and cannot connet to anything there
so they indicate they are starting points of scripts.

=over 4

=item when_started    /green flag clicked/ TODO

=item when (button) key pressed  /where button is a-z0-9 + SPACE + arrows/ TODO

=item when ThisSprite clicked TODO

=item when I received (message name) TODO

=back

=head2 Controls

=over 4

=item wait(number)

Waits number seconds.

=cut

sub wait {
	my ($self, $time) = @_;
	sleep($time);
}

=item forever /bracket/ TODO


=item repeat (number) /bracket , repeat number times/ TODO


=item broadcast (message name) TODO

=item broadcast (message name) and wait TODO

=item forever if (condition) /bracket/ TODO

=item if (condition) /bracket/ TODO

=item if (condition) /bracket/ else /bracket/ TODO

=item wait until (condition) TODO

=item repeate until (condition) TODO


=item stop_script TODO

This item does not have an outflow. 

=item stop_all TODO

This item does not ave an outflow. It stops the whole event loop. 
Similar to clicking on the red flag. (Stop button).

=pod

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

