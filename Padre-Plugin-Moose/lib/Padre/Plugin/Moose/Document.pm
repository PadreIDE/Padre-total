package Padre::Plugin::Moose::Document;

use 5.008;
use strict;
use warnings;
use Padre::Document::Perl ();

our $VERSION = '0.14';

our @ISA = 'Padre::Document::Perl';

# Override SUPER::set_editor to hook up the key down event
sub set_editor {
	my $self   = shift;
	my $editor = shift;

	$self->SUPER::set_editor($editor);

	# TODO Padre should fire event_key_down instead of this hack :)
	# Register keyboard event handler for the current editor
	Wx::Event::EVT_KEY_DOWN( $editor, undef );
	Wx::Event::EVT_KEY_DOWN(
		$editor,
		sub {
			$self->on_key_down(@_);
		}
	);

	return;
}

sub get_indentation_style {
	my $self = shift;

	# Syntax highlight Moose keywords after get_indentation_style is called :)
	# TODO remove hack once Padre supports a better way
	require Padre::Plugin::Moose::Util;
	Padre::Plugin::Moose::Util::add_moose_keywords_highlighting( $self );

	return $self->SUPER::get_indentation_style;
}

# Called when the a key is pressed
sub on_key_down {
	my $self   = shift;
	my $editor = shift;
	my $event  = shift;

	# Load snippets everytime
	require YAML::Tiny;
	require File::ShareDir;
	my $snippets = YAML::Tiny::LoadFile( File::ShareDir::dist_file( 'Padre-Plugin-Moose', 'snippets.yml' ) );

	# If it is tab key down event, we cycle through snippets
	# to find a ^match.
	# If there is a match, we paste the snippet and position the cursor to
	# the first variable
	# in this case $0

	#TODO TAB to other variables
	#TODO draw a box around values
	my $snippet_added = 0;
	if ( $event->GetKeyCode == Wx::WXK_TAB ) {
		my $position       = $editor->GetCurrentPos;
		my $start_position = $editor->PositionFromLine( $editor->LineFromPosition($position) );
		my $line           = $editor->GetTextRange( $start_position, $position );

		my $cursor = '$0';
		for my $e ( keys %$snippets ) {
			my $v = $snippets->{$e};
			if ( $line =~ /^\s*\Q$e\E$/ ) {
				$editor->SetTargetStart( $position - length($e) );
				$editor->SetTargetEnd($position);
				my $m = $v;
				$m =~ s/\$\d//g;
				$editor->ReplaceTarget($m);
				if ( $v =~ /(\Q$cursor\E)/g ) {
					$editor->GotoPos( $position - length($e) + pos($v) - length($cursor) );
				}
				$snippet_added = 1;
				last;
			}
		}


	}

	# Keep processing it there was snippet completion
	# Other consume the TAB key down event
	$event->Skip(1) unless $snippet_added;

	return;
}


1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose::Document - Padre Perl document with Moose highlighting

=cut
