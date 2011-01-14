package Padre::Wx::History::ComboBox;

=pod

=head1 NAME

Padre::Wx::History::ComboBox - A history-enabled Wx combobox

=head1 SYNOPSIS

  $dialog->{search_text} = Padre::Wx::History::ComboBox->new(
      $self,
      -1,
      '', # Use the last history value
      Wx::wxDefaultPosition,
      Wx::wxDefaultSize,
      [ 'search' ], # The history queue to read from
  );

=head1 DESCRIPTION

Padre::Wx::History::ComboBox is a normal Wx ComboBox widget, but enhanced
with the ability to remember previously entered values and present the
previous values as options the next time it is used.

This type of input memory is fairly common in dialog boxes and other task
inputs. The parameters are provided to the history box in a form compatible
with an ordinary Wx::ComboBox to simplify integration with GUI generators
such as L<Padre::Plugin::FormBuilder>.

The "options" hash should contain exactly one value, which should be the
key string for the history table. This can be a simple name, allowing the
sharing of remembered history across several different dialogs.

The "value" can be defined literally, or will be pulled from the most
recent history entry if it set to the null string.

=cut

use 5.008;
use strict;
use warnings;
use Padre::Wx          ();
use Padre::DB          ();
use Padre::DB::History ();

our $VERSION = '0.78';
our @ISA     = 'Wx::ComboBox';

sub new {
	my $class  = shift;
	my @params = @_;

	# First key in the value list to overwrite with the history values.
	my $type = $params[5]->[0];
	if ($type) {
		$params[5] = [ Padre::DB::History->recent($type) ];

		# Initial text defaults to first history item
		$params[2] ||= $params[5]->[0] || '';
	}

	my $self = $class->SUPER::new(@params);

	# Save the type, we'll need it later.
	$self->{type} = $type;

	$self;
}

sub refresh {
	my $self = shift;

	# Refresh the recent values
	my @recent = Padre::DB::History->recent( $self->{type} );

	# Update the Wx object from the list
	$self->Clear;
	foreach my $option (@recent) {
		$self->Append($option);
	}

	return 1;
}

sub GetValue {
	my $self  = shift;
	my $value = $self->SUPER::GetValue();

	# If this is a value is not in our recent list, save it.
	if ( defined $value and length $value ) {
		if ( $self->FindString($value) == Wx::wxNOT_FOUND ) {
			Padre::DB::History->create(
				type => $self->{type},
				name => $value,
			);
		}
	}

	return $value;
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
