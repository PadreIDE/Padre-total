package Padre::Wx::History::ComboBox;

# A history-enabled version of a Wx::ComboBox

use 5.008;
use strict;
use warnings;
use Padre::Wx          ();
use Padre::DB          ();
use Padre::DB::History ();

our $VERSION = '0.70';
our @ISA     = 'Wx::ComboBox';

sub new {
	my $class  = shift;
	my @params = @_;
	my $type   = $params[5];

	$params[5] = [ Padre::DB::History->recent($type) ];
	$params[2] ||= $params[5][0] || ''; # Initial text set to first history item by default

	my $self = $class->SUPER::new(@params);
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

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
