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

This plugin provides an interface to the L<Syntax::Highligh::Engine::Kate>
which implements syntax highlighting rules taken from the Kate editor.

Currently the plugin only implements Perl 5 and PHP highlighting.

Once this plug-in is installed the user can switch the highlilghting of all 
Perl 5 or PHP files to use this highlighter via the Preferences menu
of L<Padre>.


=head1 LIMITATION

This is a first attempt to integrate this synatx highlighter with Padre
and thus many things don't work well. Especially due to speed issues currently
even if you set the highlighting to use the Kate plugin Padre will do so
only for small files. The hard-coded limit is in the 
L<Padre::Document::Perl> class (which probably is a bug in itself) which
probably means it will only limit Perl files and not PHP files.

There are several ways to improve the situation e.g.

Highlight in the background

Only highlight the currently visible text

Only highlight a few lines around the the last changed character.

Each one has its own advantage and disadvantage. More research is needed.

=head1 COPYRIGHT

Copyright 2009 Gabor Szabo. L<http://szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut


sub padre_interfaces {
	return 'Padre::Plugin' => 0.41;
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
		'Padre::Plugin::Kate' => [
			'application/x-php',
			'application/x-perl',
		],
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

# Copyright 2008-2009 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.


