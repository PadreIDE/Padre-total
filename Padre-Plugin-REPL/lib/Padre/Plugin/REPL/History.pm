package Padre::Plugin::REPL::History;

use warnings;
use strict;

use Padre::Plugin::REPL;

our @history;
our @original;
our $current;
our $walking;

our $VERSION = '0.01';

sub get_text {
	Padre::Plugin::REPL::get_text();
}

sub set_text {
	Padre::Plugin::REPL::set_text( $history[$walking] );
}

sub init {
	$current = 0;
	@history = ();
	$walking = 0;
	clear();
	set_text();
}

sub update_current {
	$history[$current]  = get_text();
	$original[$current] = get_text();
}

sub validate_walking {
	$walking = 0        if ( $walking < 0 );
	$walking = $current if ( $walking > $current );
}

sub update_walking_before_leaving {
	$history[$walking] = get_text();
}

sub go_previous {
	update_walking_before_leaving();
	$walking--;
	validate_walking();
	set_text();
}

sub go_next {
	update_walking_before_leaving();
	$walking++;
	validate_walking();
	set_text();
}

sub clear {
	$history[$current] = "";
}

sub evalled {
	update_current();
	$current += 1;
	clear();
	$history[$walking] = $original[$walking];
	$walking = $current;
	set_text();
}

1;
