package Padre::Wx::Dialog;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.14';

use Padre::Wx;

use base 'Wx::Dialog';

=head1 NAME

Padre::Wx::Dialog

=head1 METHODS

=cut

=head2 new

=cut

sub new {
	my ($class, %args) = @_;

	my %default = (
		parent => undef,
		id     => -1,
		style  => Wx::wxDEFAULT_FRAME_STYLE,
		title  => '',
		pos    => [-1, -1],
		size   => [-1, -1],
	);
	%args = (%default, %args);

	my $self = $class->SUPER::new( @args{qw(parent id title pos size style)});
	$args{top_left} ||= [0, 0];
	$self->build_layout($args{layout}, $args{width}, $args{top_left}, $args{element_spacing});
	$self->{_layout_} = $args{layout};

	return $self;
}

=head2 build_layout

 build_layout($dialog, $layout, $width, $top_left_offset, $element_spacing);
 
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
	my ($dialog, $layout, $width, $top_left_offset, $element_spacing) = @_;
	$top_left_offset = [0, 0] if not ref($top_left_offset);
	$element_spacing = [0, 0] if not ref($element_spacing);

	# TODO make sure width has enough elements to the widest row
	# or maybe we should also check that all the rows has the same number of elements
	my $box  = Wx::BoxSizer->new( Wx::wxVERTICAL );
	# Add Y-offset
	$box->Add(0, $top_left_offset->[1], 0) if $top_left_offset->[1];

	foreach my $i (0..@$layout-1) {
		my $row = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
		# Add X-offset
		$row->Add($top_left_offset->[0], 0, 0) if $top_left_offset->[0];
	        $box->Add(0, $element_spacing->[1], 0) if $element_spacing->[1];
		$box->Add($row);
		foreach my $j (0..@{$layout->[$i]}-1) {
			if (not @{ $layout->[$i][$j] } ) {  # [] means Expand
				$row->Add($width->[$j], 0, 0, Wx::wxEXPAND, 0);
				next;
			}
		        $row->Add($element_spacing->[0], 0, 0) if $element_spacing->[0];
			my ($class, $name, $arg, @params) = @{ $layout->[$i][$j] };

			my $widget;
			if ($class eq 'Wx::StaticText') {
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, [$width->[$j], -1] );
			} elsif ($class eq 'Wx::Button') {
				my $s = Wx::Button::GetDefaultSize;
				#print $s->GetWidth, " ", $s->GetHeight, "\n";
				my @args = $arg =~ /[a-zA-Z]/ ? (-1, $arg) : ($arg, '');
				$widget = $class->new( $dialog, @args );
			} elsif ($class eq 'Wx::DirPickerCtrl') {
				my $title = shift(@params) || '';
				$widget = $class->new( $dialog, -1, $arg, $title, Wx::wxDefaultPosition, [$width->[$j], -1] );
				# it seems we cannot set the default directory and 
				# we still have to set this directory in order to get anything back in
				# GetPath
				$widget->SetPath(Cwd::cwd());
			} elsif ($class eq 'Wx::TextCtrl') {
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, [$width->[$j], -1]);
			} elsif ($class eq 'Wx::CheckBox') {
				my $default = shift @params;
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, [$width->[$j], -1], @params );
				$widget->SetValue($default);
			} elsif ($class eq 'Wx::ComboBox') {
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, [$width->[$j], -1], @params );
			} elsif ($class eq 'Wx::Choice') {
				$widget = $class->new( $dialog, -1, Wx::wxDefaultPosition, [$width->[$j], -1], $arg, @params );
			} elsif ($class eq 'Wx::Treebook') {
				my $height = @$arg * 27; # should be height of font
				$widget = $class->new( $dialog, -1, Wx::wxDefaultPosition, [$width->[$j], $height] );
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
	}

	$dialog->SetSizer($box);

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

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
