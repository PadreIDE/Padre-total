package Padre::Wx::Dialog;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.12';

use Padre::Wx;

=head1 NAME

Padre::Wx::Dialog

=head1 METHODS

=cut

=head2 build_layout

 build_layout($dialog, $layout, $width, $top_left_offset);

=cut
sub build_layout {
	my ($dialog, $layout, $width, $top_left_offset) = @_;
	$top_left_offset = [0, 0] if not ref($top_left_offset);

	my $box  = Wx::BoxSizer->new( Wx::wxVERTICAL );
	# Add Y-offset
	$box->Add(0, $top_left_offset->[1], 0) if $top_left_offset->[1];

	foreach my $i (0..@$layout-1) {
		my $row = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
		# Add X-offset
		$row->Add($top_left_offset->[0], 0, 0) if $top_left_offset->[0];
		$box->Add($row);
		foreach my $j (0..@{$layout->[$i]}-1) {
			if (not @{ $layout->[$i][$j] } ) {  # [] means Expand
				$row->Add($width->[$j], 0, 0, Wx::wxEXPAND, 0);
				next;
			}
			my ($class, $name, $arg, @params) = @{ $layout->[$i][$j] };

			my $widget;
			if ($class eq 'Wx::Button') {
				my ($first, $second) = $arg =~ /[a-zA-Z]/ ? (-1, $arg) : ($arg, '');
				$widget = $class->new( $dialog, $first, $second);
			} elsif ($class eq 'Wx::DirPickerCtrl') {
				my $title = shift(@params) || '';
				$widget = $class->new( $dialog, -1, $arg, $title, Wx::wxDefaultPosition, [$width->[$j], -1], @params );
				# it seems we cannot set the default directory and 
				# we still have to set this directory in order to get anything back in
				# GetPath
				$widget->SetPath(Cwd::cwd());
			} elsif ($class eq 'Wx::TextCtrl') {
				my $default = shift @params;
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, [$width->[$j], -1], @params );
				if (defined $default) {
					$widget->SetValue($default);
				}
			} elsif ($class eq 'Wx::CheckBox') {
				my $default = shift @params;
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, [$width->[$j], -1], @params );
				$widget->SetValue($default);
			} else {
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, [$width->[$j], -1], @params );
			}

			$row->Add($widget);

			if ($name) {
				$dialog->{$name} = $widget;
			}
		}
	}

	$dialog->SetSizer($box);

	return;
}

sub get_data_from {
	my ( $dialog, $layout ) = @_;

	my %data;
	foreach my $i (0..@$layout-1) {
		foreach my $j (0..@{$layout->[$i]}-1) {
			next if not @{ $layout->[$i][$j] }; # [] means Expand
			my ($class, $name, $arg, @params) = @{ $layout->[$i][$j] };
			if ($name) {
				next if $class eq 'Wx::Button';

				if ($class eq 'Wx::DirPickerCtrl') {
					$data{$name} = $dialog->{$name}->GetPath;
				} else {
					$data{$name} = $dialog->{$name}->GetValue;
				}
			}
		}
	}

	return \%data;
}

1;
