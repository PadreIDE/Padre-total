package Padre::Wx::Dialog::RegexEditor;

# The Regex Editor for Padre

use 5.008;
use strict;
use warnings;
use Padre::Wx                  ();
use Padre::Wx::Icon            ();
use Padre::Wx::Role::MainChild ();

# RichTextCtrl
use Wx::RichText ();

our $VERSION = '0.63';
our @ISA     = qw{
	Padre::Wx::Role::MainChild
	Wx::Dialog
};


######################################################################
# Constructor

sub new {
	my $class  = shift;
	my $parent = shift;

	# Create the basic object
	my $self = $class->SUPER::new(
		$parent,
		-1,
		Wx::gettext('Regex Editor'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE,
	);

	# Set basic dialog properties
	$self->SetIcon(Padre::Wx::Icon::PADRE);
	$self->SetMinSize( [ 380, 500 ] );

	# create sizer that will host all controls
	my $sizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);

	# Create the controls
	$self->_create_controls($sizer);

	# Bind the control events
	$self->_bind_events;

	# Tune the size and position it appears
	$self->SetSizer($sizer);
	$self->Fit;
	$self->CentreOnParent;

	return $self;
}


#
# A private method that returns a hash of regex groups along with their meaning
#
sub _regex_groups {
	my $self = shift;

	return (
		'00' => {
			label => Wx::gettext('&Character classes'),
			value => {
				'00.'  => Wx::gettext('Any character except a newline'),
				'01\d' => Wx::gettext('Any decimal digit'),
				'02\D' => Wx::gettext('Any non-digit'),
				'03\s' => Wx::gettext('Any whitespace character'),
				'04\S' => Wx::gettext('Any non-whitespace character'),
				'05\w' => Wx::gettext('Any word character'),
				'06\W' => Wx::gettext('Any non-word character'),
			}
		},
		'01' => {
			label => Wx::gettext('&POSIX Character classes'),
			value => {
				'00[:alpha:]'  => Wx::gettext('Alphabetic characters'),
				'01[:alnum:]'  => Wx::gettext('Alphanumeric characters'),
				'02[:ascii:]'  => Wx::gettext('7-bit US-ASCII character'),
				'03[:blank:]'  => Wx::gettext('Space and tab'),
				'04[:cntrl:]'  => Wx::gettext('Control characters'),
				'05[:digit:]'  => Wx::gettext('Digits'),
				'06[:graph:]'  => Wx::gettext('Visible characters'),
				'07[:lower:]'  => Wx::gettext('Lowercase characters'),
				'08[:print:]'  => Wx::gettext('Visible characters and spaces'),
				'09[:punct:]'  => Wx::gettext('Punctuation characters'),
				'10[:space:]'  => Wx::gettext('Whitespace characters'),
				'11[:upper:]'  => Wx::gettext('Uppercase characters'),
				'12[:word:]'   => Wx::gettext('Alphanumeric characters plus "_"'),
				'13[:xdigit:]' => Wx::gettext('Hexadecimal digits'),
			}
		},
		'02' => {
			label => Wx::gettext('&Quantifiers'),
			value => {
				'00*'     => Wx::gettext('Match 0 or more times'),
				'01+'     => Wx::gettext('Match 1 or more times'),
				'02?'     => Wx::gettext('Match 1 or 0 times'),
				'03{m}'   => Wx::gettext('Match exactly m times'),
				'05{n,}'  => Wx::gettext('Match at least n times'),
				'05{m,n}' => Wx::gettext('Match at least m but not more than n times'),
			}
		},
		'03' => {
			label => Wx::gettext('&Miscellaneous'),
			value => {
				'00|'     => Wx::gettext('Alternation'),
				'01[ ]'   => Wx::gettext('Character set'),
				'02^'     => Wx::gettext('Beginning of line'),
				'03$'     => Wx::gettext('End of line'),
				'04\b'    => Wx::gettext('A word boundary'),
				'05\B'    => Wx::gettext('Not a word boundary'),
				'06(?# )' => Wx::gettext('A comment'),
			}
		},
		'04' => {
			label => Wx::gettext('&Grouping constructs'),
			value => {
				'00( )'    => Wx::gettext('A group'),
				'01(?: )'  => Wx::gettext('Non-capturing group'),
				'02(?= )'  => Wx::gettext('Positive lookahead assertion'),
				'03(?! )'  => Wx::gettext('Negative lookahead assertion'),
				'04(?<=)'  => Wx::gettext('Positive lookbehind assertion'),
				'05(?<! )' => Wx::gettext('Negative lookbehind assertion'),
				'06\n'     => Wx::gettext('Backreference to the nth group'),
			}
		}
	);
}

sub _create_controls {
	my ( $self, $sizer ) = @_;

	# Dialog Controls

	# Regex text field
	my $regex_label = Wx::StaticText->new( $self, -1, Wx::gettext('&Regular expression:') );
	$self->{regex} = Wx::RichTextCtrl->new(
		$self, -1, '', Wx::wxDefaultPosition, Wx::wxDefaultSize,
		Wx::wxRE_MULTILINE | Wx::wxWANTS_CHARS # Otherwise arrows will not work on win32
	);

	# Replace regex text field
	my $replace_label = Wx::StaticText->new( $self, -1, Wx::gettext('&Replace text with:') );
	$self->{replace} = Wx::TextCtrl->new(
		$self, -1, '', Wx::wxDefaultPosition, Wx::wxDefaultSize,
		Wx::wxTE_MULTILINE | Wx::wxNO_FULL_REPAINT_ON_RESIZE
	);

	# Describe-the-regex text field
	my $description_label = Wx::StaticText->new( $self, -1, Wx::gettext('&Description:') );
	$self->{description_text} = Wx::TextCtrl->new(
		$self, -1, '', Wx::wxDefaultPosition, Wx::wxDefaultSize,
		Wx::wxTE_MULTILINE | Wx::wxNO_FULL_REPAINT_ON_RESIZE
	);

	# Original input text field
	my $original_label = Wx::StaticText->new( $self, -1, Wx::gettext('&Original text:') );
	$self->{original_text} = Wx::TextCtrl->new(
		$self, -1, '', Wx::wxDefaultPosition, Wx::wxDefaultSize,
		Wx::wxTE_MULTILINE | Wx::wxNO_FULL_REPAINT_ON_RESIZE
	);

	# Matched readonly text field
	my $matched_label = Wx::StaticText->new( $self, -1, Wx::gettext('&Matched text:') );
	$self->{matched_text} = Wx::RichTextCtrl->new(
		$self, -1, '', Wx::wxDefaultPosition, Wx::wxDefaultSize,
		Wx::wxRE_MULTILINE | Wx::wxRE_READONLY | Wx::wxWANTS_CHARS # Otherwise arrows will not work on win32
	);

	# Result from replace text field
	my $result_label = Wx::StaticText->new( $self, -1, Wx::gettext('&Result from replace:') );
	$self->{result_text} = Wx::RichTextCtrl->new(
		$self, -1, '', Wx::wxDefaultPosition, Wx::wxDefaultSize,
		Wx::wxRE_MULTILINE | Wx::wxRE_READONLY | Wx::wxWANTS_CHARS # Otherwise arrows will not work on win32
	);

	# Modifiers
	my %m = $self->_modifiers();
	foreach my $name ( keys %m ) {
		$self->{$name} = Wx::CheckBox->new(
			$self,
			-1,
			$m{$name}{name},
		);
	}

	my %regex_groups = $self->_regex_groups;
	foreach my $code ( sort keys %regex_groups ) {
		my %sub_group   = %{ $regex_groups{$code} };
		my $button_name = $code . '_button';
		$self->{$button_name} = Wx::Button->new(
			$self, -1, $sub_group{label},
		);

		my $menu_name = $code . '_menu';

		Wx::Event::EVT_BUTTON(
			$self,
			$self->{$button_name},
			sub {
				my @pos  = $self->{$button_name}->GetPositionXY;
				my @size = $self->{$button_name}->GetSizeWH;
				$self->PopupMenu( $self->{$menu_name}, $pos[0], $pos[1] + $size[1] );
			},
		);

		$self->{$menu_name} = Wx::Menu->new;
		my %sub_group_value = %{ $sub_group{value} };
		foreach my $element ( sort keys %sub_group_value ) {
			my $label = $element;
			$label =~ s/^\d{2}//;
			my $menu_item = $self->{$menu_name}->Append( -1, $label . '  ' . $sub_group_value{$element} );

			Wx::Event::EVT_MENU(
				$self,
				$menu_item,
				sub {
					$_[0]->{regex}->WriteText($label);
				},
			);
		}
	}


	# Insert regex into current document button_name
	$self->{insert_button} = Wx::Button->new(
		$self, -1, Wx::gettext('&Insert'),
	);

	# Close button
	$self->{close_button} = Wx::Button->new(
		$self, Wx::wxID_CANCEL, Wx::gettext('&Close'),
	);

	my $buttons = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$buttons->AddStretchSpacer;
	$buttons->Add( $self->{insert_button}, 0, Wx::wxALL, 1 );
	$buttons->Add( $self->{close_button},  0, Wx::wxALL, 1 );
	$buttons->AddStretchSpacer;

	# Dialog Layout

	my $modifiers = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$modifiers->AddStretchSpacer;
	$modifiers->Add( $self->{ignore_case}, 0, Wx::wxALL, 1 );
	$modifiers->Add( $self->{single_line}, 0, Wx::wxALL, 1 );
	$modifiers->Add( $self->{multi_line},  0, Wx::wxALL, 1 );
	$modifiers->Add( $self->{extended},    0, Wx::wxALL, 1 );
	$modifiers->Add( $self->{global},      0, Wx::wxALL, 1 );

	$modifiers->AddStretchSpacer;

	my $regex = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$regex->Add( $self->{regex}, 1, Wx::wxALL | Wx::wxEXPAND, 1 );

	my $regex_groups = Wx::BoxSizer->new(Wx::wxVERTICAL);
	foreach my $code ( sort keys %regex_groups ) {
		my $button_name = $code . '_button';
		$regex_groups->Add( $self->{$button_name}, 0, Wx::wxEXPAND, 1 );
	}

	my $combined = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$combined->Add( $regex,        2, Wx::wxALL | Wx::wxEXPAND, 0 );
	$combined->Add( $regex_groups, 0, Wx::wxALL | Wx::wxEXPAND, 0 );

	# Vertical layout of the left hand side
	my $left = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$left->Add( $modifiers, 0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$left->AddSpacer(5);
	$left->Add( $regex_label,              0, Wx::wxALL | Wx::wxEXPAND, 1 );
	$left->Add( $combined,                 0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$left->Add( $description_label,        0, Wx::wxALL | Wx::wxEXPAND, 1 );
	$left->Add( $self->{description_text}, 2, Wx::wxALL | Wx::wxEXPAND, 1 );

	$left->Add( $replace_label,   0, Wx::wxALL | Wx::wxEXPAND, 1 );
	$left->Add( $self->{replace}, 1, Wx::wxALL | Wx::wxEXPAND, 1 );

	$left->Add( $original_label,        0, Wx::wxALL | Wx::wxEXPAND, 1 );
	$left->Add( $self->{original_text}, 1, Wx::wxALL | Wx::wxEXPAND, 1 );
	$left->Add( $matched_label,         0, Wx::wxALL | Wx::wxEXPAND, 1 );
	$left->Add( $self->{matched_text},  1, Wx::wxALL | Wx::wxEXPAND, 1 );
	$left->Add( $result_label,          0, Wx::wxALL | Wx::wxEXPAND, 1 );
	$left->Add( $self->{result_text},   1, Wx::wxALL | Wx::wxEXPAND, 1 );
	$left->AddSpacer(5);
	$left->Add( $buttons, 0, Wx::wxALL | Wx::wxEXPAND, 1 );

	# Main sizer
	$sizer->Add( $left, 1, Wx::wxALL | Wx::wxEXPAND, 5 );
}

sub _bind_events {
	my $self = shift;

	Wx::Event::EVT_TEXT(
		$self,
		$self->{regex},
		sub { $_[0]->run; },
	);
	Wx::Event::EVT_TEXT(
		$self,
		$self->{replace},
		sub { $_[0]->run; },
	);
	Wx::Event::EVT_TEXT(
		$self,
		$self->{original_text},
		sub { $_[0]->run; },
	);

	# Modifiers
	my %modifiers = $self->_modifiers();
	foreach my $name ( keys %modifiers ) {
		Wx::Event::EVT_CHECKBOX(
			$self,
			$self->{$name},
			sub {
				$_[0]->box_clicked($name);
			},
		);
	}

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{insert_button},
		sub {
			my $self = shift;
			my $editor = $self->current->editor or return;
			$editor->InsertText( $editor->GetCurrentPos, $self->{regex}->GetValue );
		},
	);
}


#
# A private method that returns a hash of regex modifiers
#
sub _modifiers {
	my $self = shift;
	return (
		ignore_case => { mod => 'i', name => sprintf( Wx::gettext('&Ignore case (%s)'), 'i' ) },
		single_line => { mod => 's', name => sprintf( Wx::gettext('&Single-line (%s)'), 's' ) },
		multi_line  => { mod => 'm', name => sprintf( Wx::gettext('&Multi-line (%s)'),  'm' ) },
		extended    => { mod => 'x', name => sprintf( Wx::gettext('&Extended (%s)'),    'x' ) },
		global      => { mod => 'g', name => sprintf( Wx::gettext('&Global (%s)'),      'g' ) },
	);
}


# -- public methods

sub show {
	my $self = shift;

	if ( $self->IsShown ) {
		$self->SetFocus;
	} else {
		my $editor = $self->current->editor;
		if ($editor) {
			my $selection        = $editor->GetSelectedText;
			my $selection_length = length $selection;
			if ( $selection_length > 0 ) {
				$self->{regex}->ChangeValue($selection);
			} else {
				$self->{regex}->ChangeValue('\w+');
			}
		} else {
			$self->{regex}->ChangeValue('\w+');
		}

		$self->{replace}->ChangeValue("Baz");
		$self->{original_text}->SetValue("Foo Bar");

		$self->Show;
	}

	$self->{regex}->SetFocus;

	return;
}

#
# Private method to dump the regular expression
# description as text
#
sub _dump_regex {
	my ( $self, $parent, $str, $level ) = @_;
	$str   = '' unless $str;
	$level = 0  unless $level;
	my @children = $parent->isa('PPIx::Regexp::Node') ? $parent->children : ();
	foreach my $child (@children) {
		next if $child->content eq '';
		my $class_name = $child->class;
		$class_name =~ s/PPIx::Regexp:://;
		$str .= ( " " x ( $level * 4 ) ) . $class_name . "     (" . $child->content . ")\n";
		$str = $self->_dump_regex( $child, $str, $level + 1 );
	}
	return $str;
}

#
# Private method to return all the parsed regex elements as an array
#
sub _parse_regex_elements {
	my ( $parent, $position, @array ) = @_;
	$position = 0  unless $position;
	@array    = () unless @array;
	my @elements = $parent->isa('PPIx::Regexp::Node') ? $parent->elements : ();
	foreach my $element (@elements) {
		my $content = $element->content;
		next if $content eq '';
		my $class_name = $element->class;
		push @array,
			{
			element => $element,
			offset  => $position,
			len     => length $content
			};
		@array = _parse_regex_elements( $element, $position, @array );
		$position += length $content;
	}
	return @array;
}

sub run {
	my $self = shift;

	my $regex = $self->{regex}->GetRange( 0, $self->{regex}->GetLastPosition );
	my $original_text = $self->{original_text}->GetRange( 0, $self->{original_text}->GetLastPosition );
	my $replace = $self->{replace}->GetRange( 0, $self->{replace}->GetLastPosition );
	my $result_text = $original_text;


	my $start     = '';
	my $end       = '';
	my %modifiers = $self->_modifiers();
	foreach my $name ( keys %modifiers ) {
		if ( $self->{$name}->IsChecked ) {
			$start .= $modifiers{$name}{mod};
		} else {
			$end .= $modifiers{$name}{mod};
		}
	}
	my $xism = "$start-$end";

	$self->{matched_text}->Clear;
	$self->{result_text}->Clear;

	$self->{matched_text}->BeginTextColour(Wx::wxBLACK);

	my $match;
	my $match_start;
	my $match_end;

	my $warning;

	# XXX Ignore Win32::API warnings. It's ugly but it works :)
	local $SIG{__WARN__} = sub { $warning = $_[0] };

	eval {

		# /g modifier is useless in this case
		# TODO loop on all matches
		$xism =~ s/g//g;
		if ( $original_text =~ /(?$xism:$regex)/ ) {
			$match_start = $-[0];
			$match_end   = $+[0];
			$match       = substr( $original_text, $match_start, $match_end - $match_start );
		}
	};
	if ($@) {
		$self->{matched_text}->BeginTextColour(Wx::wxRED);
		$self->{matched_text}->SetValue( sprintf( Wx::gettext("Match failure in %s:  %s"), $regex, $@ ) );
		$self->{matched_text}->EndTextColour;
		return;
	}

	if ($warning) {
		$self->{matched_text}->BeginTextColour(Wx::wxRED);
		$self->{matched_text}->SetValue( sprintf( Wx::gettext("Match warning in %s:  %s"), $regex, $warning ) );
		$self->{matched_text}->EndTextColour;
		return;
	}

	if ( defined $match ) {
		my @chars = split( //, $original_text );
		my $pos = 0;
		foreach my $char (@chars) {
			if ( $pos == $match_start ) {
				$self->{matched_text}->BeginTextColour(Wx::wxRED);
			} elsif ( $pos == $match_end ) {
				$self->{matched_text}->EndTextColour;
			}
			$self->{matched_text}->AppendText($char);
			$pos++;
		}
	} else {
		$self->{matched_text}->BeginTextColour(Wx::wxRED);
		$self->{matched_text}->SetValue( Wx::gettext('No match') );
		$self->{matched_text}->EndTextColour;
	}

	eval {
		if ( $self->{global}->IsChecked )
		{
			$result_text =~ s{(?$xism:$regex)}{$replace}g;
		} else {
			$result_text =~ s{(?$xism:$regex)}{$replace};
		}
	};
	if ($@) {
		$self->{result_text}->BeginTextColour(Wx::wxRED);
		$self->{result_text}->AppendText( sprintf( Wx::gettext('Replace failure in %s:  %s'), $regex, $@ ) );
		$self->{result_text}->EndTextColour;
		return;
	}

	if ( defined $result_text ) {
		$self->{result_text}->SetValue($result_text);
	}

	$self->{matched_text}->EndTextColour;

	require PPIx::Regexp;
	my $regexp = PPIx::Regexp->new("/$regex/");
	$self->{description_text}->SetValue( $self->_dump_regex($regexp) );

	#	$self->{regex}->Clear;
	#	my @elements = _parse_regex_elements;
	#	foreach my $element (@elements) {
	#		my $class_name = $element->element->class;
	#		if ($class_name eq 'PPIx::Regexp::Token::CharClass::Simple') {
	#			$self->{regex}->BeginTextColour(Wx::wxRED);
	#		} elsif( $class_name eq 'PPIx::Regexp::Token::Quantifier') {
	#			$self->{regex}->BeginTextColour(Wx::wxBLUE);
	#		} elsif( $class_name eq 'PPIx::Regexp::Token::Operator') {
	#			$self->{regex}->BeginTextColour(Wx::wxLIGHT_GREY);
	#		} elsif( $class_name eq 'PPIx::Regexp::Structure::Capture') {
	#			$self->{regex}->BeginTextColour(Wx::wxCYAN);
	#		}
	#		$self->{regex}->AppendText($element->content);
	#	$self->{regex}->EndTextColour;
	#	}

	return;
}

sub box_clicked {
	my $self = shift;
	$self->run();
	return;
}

1;

__END__

=pod

=head1 NAME

Padre::Wx::Dialog::RegexEditor - dialog to make it easy to create a regular expression

=head1 DESCRIPTION


The C<Regex Editor> provides an interface to easily create regular
expressions used in Perl.

The user can insert a regular expression (the surrounding C</> characters are not
needed) and a text. The C<Regex Editor> will automatically display the matching
text in the bottom right window.


At the top of the window the user can select any of the four
regular expression modifiers:

=over

=item Ignore case (i)

=item Single-line (s)

=item Multi-line (m)

=item Extended (x)

=back

Global match

Allow the change/replacement of the // around the regular expression

Highlight the match in the source text instead of in
a separate window

Display the captured groups in a tree hierarchy similar to Rx ?

  Group                  Span (character) Value
  Match 0 (Group 0)      4-7              the actual match

Display the various Perl variable containing the relevant values
e.g. the C<@-> and C<@+> arrays, the C<%+> hash
C<$1>, C<$2>...

point out what to use instead of C<$@> and C<$'> and C<$`>

English explanation of the regular expression

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
