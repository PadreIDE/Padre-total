package Wx::Perl::Dialog;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.02';

use Wx ':everything';

use base 'Wx::Dialog';

=head1 NAME

Wx::Perl::Dialog - Abstract dialog class for simple dialog creation

=head1 METHODS

=cut

=head2 new

=cut

sub new {
	my ($class, %args) = @_;

	my %default = (
		parent          => undef,
		id              => -1,
		style           => Wx::wxDEFAULT_FRAME_STYLE,
		title           => '',
		pos             => [-1, -1],
		size            => [-1, -1],
		
		top             => 5,
		left            => 5,
		bottom          => 20,
		right           => 5,
		element_spacing => [0, 5],
	);
	%args = (%default, %args);

	my $self = $class->SUPER::new( @args{qw(parent id title pos size style)});
	$self->build_layout( map {$_ => $args{$_} } qw(layout width top left bottom right element_spacing) );
	$self->{_layout_} = $args{layout};

	return $self;
}

=head2 build_layout

 $dialog->build_layout(
	layout          => $layout,
	width           => $width,
	top             => $top
	left            => $left, 
	element_spacing => $element_spacing,
	);
 
The layout is reference to a two dimensional array.
Every element (an array) represents one line in the dialog.

Every element in the internal array is an array that describes a widget.

The first value in each widget description is the type of the widget.

The second value is an identifyer (or undef if we don't need any access to the widget).

The widget will be accessible form the dialog object using $dialog->{_widgets}{identifyer}

The rest of the values in the array depend on the widget.

Supported widgets and their parameters:

=over 4

=item Wx::StaticText

 3.: "the text",

=item Wx::Button

 3.: button type (stock item such as Wx::wxID_OK or string "&do this")
 
=item Wx::DirPickerCtrl

 3. default directory (must be '')  ???
 4. title to show on the directory browser 

=item Wx::TextCtrl

 3. default value, if any

=item Wx::Treebook

 3. array ref for list of values


=back

=cut

sub build_layout {
	my ($dialog, %args) = @_;

	# TODO make sure width has enough elements to the widest row
	# or maybe we should also check that all the rows has the same number of elements
	my $box  = Wx::BoxSizer->new( Wx::wxVERTICAL );
	
	# Add top margin
	$box->Add(0, $args{top}, 0) if $args{top};

	foreach my $i (0..@{$args{layout}}-1) {
		my $row = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
		$box->Add(0, $args{element_spacing}[1], 0) if $args{element_spacing}[1] and $i;
		$box->Add($row);

		# Add left margin
		$row->Add($args{left}, 0, 0) if $args{left};
		
		foreach my $j (0..@{$args{layout}[$i]}-1) {
			my $width = [$args{width}[$j], -1];

			if (not @{ $args{layout}[$i][$j] } ) {  # [] means Expand
				$row->Add($args{width}[$j], 0, 0, Wx::wxEXPAND, 0);
				next;
			}
			$row->Add($args{element_spacing}[0], 0, 0) if $args{element_spacing}[0] and $j;
			my ($class, $name, $arg, @params) = @{ $args{layout}[$i][$j] };

			my $widget;
			if ($class eq 'Wx::StaticText') {
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, $width );
			} elsif ($class eq 'Wx::Button') {
				my $s = Wx::Button::GetDefaultSize;
				#print $s->GetWidth, " ", $s->GetHeight, "\n";
				my @args = $arg =~ /[a-zA-Z]/ ? (-1, $arg) : ($arg, '');
				my $size = Wx::Button::GetDefaultSize();
				$widget = $class->new( $dialog, @args, Wx::wxDefaultPosition, $size );
			} elsif ($class eq 'Wx::DirPickerCtrl') {
				my $title = shift(@params) || '';
				$widget = $class->new( $dialog, -1, $arg, $title, Wx::wxDefaultPosition, $width );
				# it seems we cannot set the default directory and 
				# we still have to set this directory in order to get anything back in
				# GetPath
				$widget->SetPath(Cwd::cwd());
			} elsif ($class eq 'Wx::FilePickerCtrl') {
				my $title = shift(@params) || '';
				$widget = $class->new( $dialog, -1, $arg, $title, Wx::wxDefaultPosition, $width );
				$widget->SetPath(Cwd::cwd());
			} elsif ($class eq 'Wx::TextCtrl') {
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, $width );
			} elsif ($class eq 'Wx::CheckBox') {
				my $default = shift @params;
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, $width, @params );
				$widget->SetValue($default);
			} elsif ($class eq 'Wx::ComboBox') {
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, $width, @params );
			} elsif ($class eq 'Wx::Choice') {
				$widget = $class->new( $dialog, -1, Wx::wxDefaultPosition, $width, $arg, @params );
				$widget->SetSelection(0);
			} elsif ($class eq 'Wx::Treebook') {
				my $height = @$arg * 27; # should be height of font
				$widget = $class->new( $dialog, -1, Wx::wxDefaultPosition, [$args{width}[$j], $height] );
				foreach my $name ( @$arg ) {
					my $count = $widget->GetPageCount;
					my $page  = Wx::Panel->new( $widget );
					$widget->AddPage( $page, $name, 0, $count );
				}
			} else {
				warn "Unsupported widget $class\n";
				next;
			}

			$row->Add($widget);

			if ($name) {
				$dialog->{_widgets_}{$name} = $widget;
			}
		}
		$row->Add($args{right}, 0, 0, Wx::wxEXPAND, 0) if $args{right}; # margin
	}
	$box->Add(0, $args{bottom}, 0) if $args{bottom}; # margin

	$dialog->SetSizerAndFit($box);

	return;
}

sub get_data {
	my ( $dialog ) = @_;

	my $layout = $dialog->{_layout_};
	my %data;
	foreach my $i (0..@$layout-1) {
		foreach my $j (0..@{$layout->[$i]}-1) {
			next if not @{ $layout->[$i][$j] }; # [] means Expand
			my ($class, $name, $arg, @params) = @{ $layout->[$i][$j] };
			if ($name) {
				next if $class eq 'Wx::Button';

				if ($class eq 'Wx::DirPickerCtrl') {
					$data{$name} = $dialog->{_widgets_}{$name}->GetPath;
				} elsif ($class eq 'Wx::FilePickerCtrl') {
					$data{$name} = $dialog->{_widgets_}{$name}->GetPath;
				} elsif ($class eq 'Wx::Choice') {
					$data{$name} = $dialog->{_widgets_}{$name}->GetSelection;
				} else {
					$data{$name} = $dialog->{_widgets_}{$name}->GetValue;
				}
			}
		}
	}

	return \%data;
}

sub show_modal {
	my ( $dialog ) = @_;

	my $ret = $dialog->ShowModal;
	if ( $ret eq Wx::wxID_CANCEL ) {
		$dialog->Destroy;
		return;
	} else {
		return $ret;
	}
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
