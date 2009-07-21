package Padre::Plugin::Kate;
use strict;
use warnings;
use 5.008;

our $VERSION = '0.01';

use Padre::Wx ();
use Padre::Current;

use base 'Padre::Plugin';

=head1 NAME

Padre::Plugin::Kate - Using the Kate syntax highlighter

=head1 SYNOPSIS

=head1 COPYRIGHT

Copyright 2009 Gabor Szabo. L<http://szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut


sub padre_interfaces {
	return 'Padre::Plugin' => 0.26;
}

sub plugin_name {
	'Kate';
}


sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->about },
	];
}

sub provided_highlighters { 
	return (
		['Padre::Plugin::Kate', 'Kate', 'Using Syntax::Highlight::Engine::Kate based on the Kate editor'],
	);
}

sub highlighting_mime_types {
	return (
		'Padre::Plugin::Kate' => ['application/x-php'],
		'Padre::Plugin::Kate' => ['application/x-perl'],
	);
}

# TODO shall we create a module for each mime-type and register it as a highlighter
# or is our dispatching ok?
# Shall we create a module called Pudre::Plugin::Kate::Colorize that will do the dispatching ?
# now this is the mapping to the Kate highlighter engine
my %d = (
	'application/x-php'  => 'Perl', #  why ?
	'application/x-perl' => 'Perl',
);
use Syntax::Highlight::Engine::Kate::All;
use Syntax::Highlight::Engine::Kate;

sub colorize {
	my ( $self, $first ) = @_;

	my $doc = Padre::Current->document;
	my $mime_type = $doc->get_mimetype;
	if ( not $d{$mime_type} ) {
		warn("Invalid mime-type ($mime_type) passed to the Kate highlighter");
		return;
	}

	# TODO we might need not remove all the color, just from a certain section
	# TODO reuse the $first passed to the method
	$doc->remove_color;

	my $editor = $doc->editor;
	my $text   = $doc->text_get;

	my $kate = Syntax::Highlight::Engine::Kate->new(
		language => $d{$mime_type},
	);

	# returns a list of pairs: string, type
	my @tokens = $kate->highlight($text);
	my %COLOR = (
		Normal => 0,
		Operator => 1,
		String => 2,
		Function => 3,
		DataType => 4,
		Variable => 5,
		Float => 6,
		Keyword => 7,
		Char => 8,
		Comment => 9,
		
		DecVal => 10,
		Alert => 11,
		BaseN => 12,
		Others => 13,
		
	);

	my $start = 0;
	my $end   = 0;
	while (@tokens) {
		my $string = shift @tokens;
		my $type   = shift @tokens;
		#$type ||= 'Normal';
		#print "'$string'    '$type'\n";
		my $color = $COLOR{$type};
		if (not defined $color) {
			warn "Missing color definition for type '$type'\n";
			$color = 0;
		}
		my $length = length($string);
		#$end += $length;
		$editor->StartStyling( $start, $color );
		$editor->SetStyling( $length, $color );
		#$start = $end;
		$start += $length;
	}
	return;
}


sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName(__PACKAGE__);
	$about->SetDescription("Trying to use Syntax::Highlight::Engine::Kate for syntax highlighting\n" );
	$about->SetVersion($VERSION);
	Wx::AboutBox($about);
	return;
}


1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.


