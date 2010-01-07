package Padre::Wx::Dialog::RegexEditor;

# The Regex Editor for Padre

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Wx       ();
use Padre::Wx::Icon ();

our $VERSION = '0.54';
our @ISA     = 'Wx::Dialog';


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
	$self->SetMinSize( [ 750, 550 ] );

	# Dialog Controls

	$self->{regex} = Wx::TextCtrl->new(
		$self, -1, '', Wx::wxDefaultPosition, Wx::wxDefaultSize,
		Wx::wxTE_MULTILINE | Wx::wxNO_FULL_REPAINT_ON_RESIZE
	);

	$self->{substitute} = Wx::TextCtrl->new(
		$self, -1, '', Wx::wxDefaultPosition, Wx::wxDefaultSize,
		Wx::wxTE_MULTILINE | Wx::wxNO_FULL_REPAINT_ON_RESIZE
	);

	$self->{original_text} = Wx::TextCtrl->new(
		$self, -1, '', Wx::wxDefaultPosition, Wx::wxDefaultSize,
		Wx::wxTE_MULTILINE | Wx::wxNO_FULL_REPAINT_ON_RESIZE
	);

	$self->{matched_text} = Wx::TextCtrl->new(
		$self, -1, '', Wx::wxDefaultPosition, Wx::wxDefaultSize,
		Wx::wxTE_MULTILINE | Wx::wxNO_FULL_REPAINT_ON_RESIZE
	);

	Wx::Event::EVT_TEXT(
		$self,
		$self->{regex},
		sub { $_[0]->run; },
	);
	Wx::Event::EVT_TEXT(
		$self,
		$self->{substitute},
		sub { $_[0]->run; },
	);
	Wx::Event::EVT_TEXT(
		$self,
		$self->{original_text},
		sub { $_[0]->run; },
	);

	# Modifiers
	my %m = _modifiers();
	foreach my $name ( keys %m ) {
		$self->{$name} = Wx::CheckBox->new(
			$self,
			-1,
			$m{$name}{name},
		);
		Wx::Event::EVT_CHECKBOX(
			$self,
			$self->{$name},
			sub {
				$_[0]->box_clicked($name);
			},
		);
	}

	$self->{matching} = Wx::RadioButton->new(
		$self,
		-1,
		'Matching',
	);
	Wx::Event::EVT_RADIOBUTTON( $self, $self->{matching}, sub { $_[0]->run; } );
	$self->{substituting} = Wx::RadioButton->new(
		$self,
		-1,
		'Substituting',
	);
	Wx::Event::EVT_RADIOBUTTON( $self, $self->{substituting}, sub { $_[0]->run; } );

	# Buttons
	#	$self->{button_match} = Wx::Button->new(
	#		$self,
	#		-1,
	#		Wx::gettext('&Match'),
	#	);
	#	Wx::Event::EVT_BUTTON(
	#		$self,
	#		$self->{button_match},
	#		sub {
	#			$_[0]->button_match;
	#		},
	#	);
	#
	#	# Preferences Button
	#	$self->{button_replace} = Wx::Button->new(
	#		$self,
	#		-1,
	#		Wx::gettext('&Replace'),
	#	);
	#	Wx::Event::EVT_BUTTON(
	#		$self,
	#		$self->{button_replace},
	#		sub {
	#			$_[0]->button_replace;
	#		},
	#	);

	# Close Button
	$self->{button_close} = Wx::Button->new(
		$self,
		Wx::wxID_CANCEL,
		Wx::gettext('&Close'),
	);
	Wx::Event::EVT_BUTTON(
		$self,
		$self->{button_close},
		sub {
			$_[0]->button_close;
		},
	);

	# Dialog Layout

	# Horizontal button sizer
	my $buttons = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$buttons->AddStretchSpacer;
	$buttons->Add( $self->{button_match},   0, Wx::wxALL, 1 );
	$buttons->Add( $self->{button_replace}, 0, Wx::wxALL, 1 );
	$buttons->AddStretchSpacer;
	$buttons->Add( $self->{button_close}, 0, Wx::wxALL, 1 );
	$buttons->AddStretchSpacer;


	my $modifiers = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$modifiers->AddStretchSpacer;
	$modifiers->Add( $self->{ignore_case}, 0, Wx::wxALL, 1 );
	$modifiers->Add( $self->{single_line}, 0, Wx::wxALL, 1 );
	$modifiers->Add( $self->{multi_line},  0, Wx::wxALL, 1 );
	$modifiers->Add( $self->{extended},    0, Wx::wxALL, 1 );

	my $operation = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$operation->AddStretchSpacer;
	$operation->Add( $self->{matching},     0, Wx::wxALL, 1 );
	$operation->Add( $self->{substituting}, 0, Wx::wxALL, 1 );

	# Vertical layout of the left hand side
	my $left = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$left->Add( $modifiers, 0, Wx::wxALL | Wx::wxEXPAND, 1 );
	$left->Add( $operation, 0, Wx::wxALL | Wx::wxEXPAND, 1 );
	$left->Add(
		$self->{regex},
		1,
		Wx::wxALL | Wx::wxALIGN_TOP | Wx::wxALIGN_CENTER_HORIZONTAL | Wx::wxEXPAND,
		1
	);
	$left->Add(
		$self->{substitute},
		1,
		Wx::wxALL | Wx::wxALIGN_TOP | Wx::wxALIGN_CENTER_HORIZONTAL | Wx::wxEXPAND,
		1
	);


	# Vertical layout of the right hand side
	my $right = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$right->Add(
		$self->{original_text},
		1,
		Wx::wxALL | Wx::wxALIGN_TOP | Wx::wxALIGN_CENTER_HORIZONTAL | Wx::wxEXPAND,
		1
	);
	$right->Add(
		$self->{matched_text},
		1,
		Wx::wxALL | Wx::wxALIGN_TOP | Wx::wxALIGN_CENTER_HORIZONTAL | Wx::wxEXPAND,
		1
	);
	$right->Add( $buttons, 0, Wx::wxALL | Wx::wxEXPAND, 1 );



	# Main sizer
	my $sizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$sizer->Add( $left,  0, Wx::wxALL | Wx::wxEXPAND, 1 );
	$sizer->Add( $right, 1, Wx::wxALL | Wx::wxEXPAND, 1 );

	# Tune the size and position it appears
	$self->SetSizer($sizer);
	$self->Fit;
	$self->CentreOnParent;

	return $self;
}


sub _modifiers {
	return (
		ignore_case => { mod => 'i', name => sprintf( Wx::gettext('Ignore case (%s)'), 'i' ) },
		single_line => { mod => 's', name => sprintf( Wx::gettext('Single-line (%s)'), 's' ) },
		multi_line  => { mod => 'm', name => sprintf( Wx::gettext('Multi-line (%s)'),  'm' ) },
		extended    => { mod => 'x', name => sprintf( Wx::gettext('Extended (%s)'),    'x' ) },
	);
}


# -- public methods

sub show {
	my $self = shift;

	$self->{regex}->AppendText("regex");
	$self->{substitute}->AppendText("substitute");
	$self->{original_text}->AppendText("Original text");
	$self->{matching}->SetValue(1);

	$self->Show;
}

#
# $self->button_match;
#
# handler called when the Match button has been clicked.
#
sub button_match {
	my $self = shift;
	$self->run();
	return;
}

sub run {
	my $self = shift;

	my $regex = $self->{regex}->GetRange( 0, $self->{regex}->GetLastPosition );
	my $original_text = $self->{original_text}->GetRange( 0, $self->{original_text}->GetLastPosition );
	my $substitute = $self->{substitute}->GetRange( 0, $self->{substitute}->GetLastPosition );


	my $start = '';
	my $end   = '';
	my %m     = _modifiers();
	foreach my $name ( keys %m ) {
		if ( $self->{$name}->IsChecked ) {
			$start .= $m{$name}{mod};
		} else {
			$end .= $m{$name}{mod};
		}
	}
	my $xism = "$start-$end";

	$self->{matched_text}->Clear;

	if ( $self->{matching}->GetValue ) {
		my $match;
		eval {
			if ( $original_text =~ /(?$xism:$regex)/ )
			{
				$match = substr( $original_text, $-[0], $+[0] - $-[0] );
			}
		};
		if ($@) {
			my $main = Padre->ide->wx->main;

			#$main->message("Match failure in $regex:  $@");
			$self->{matched_text}->AppendText("Match failure in $regex:  $@");
			return;
		}

		if ( defined $match ) {
			$self->{matched_text}->AppendText("Matched '$match'");
		} else {
			$self->{matched_text}->AppendText("No match");
		}
	} else {
		$self->{matched_text}->AppendText("Substitute not yet implemented");
	}

	return;
}

#
# $self->button_replace;
#
# handler called when the Match button has been clicked.
#
sub button_replace {
	my $self = shift;
	my $main = Padre->ide->wx->main;
	$main->message("Replace");
	return;
}


sub box_clicked {
	my $self = shift;

	#my $box  = shift;
	$self->run();

	#my $main = Padre->ide->wx->main;
	#$main->message("Box $box");
	return;

}

#
# $self->button_close;
#
# handler called when the close button has been clicked.
#
sub button_close {
	$_[0]->Destroy;
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

=head1 TO DO

Implement substitute as well

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
