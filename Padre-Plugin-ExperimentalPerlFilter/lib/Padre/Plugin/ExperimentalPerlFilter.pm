package Padre::Plugin::ExperimentalPerlFilter;

use 5.008;
use strict;
use warnings;
use Padre::Constant ();
use Padre::Wx       ();
use Padre::Plugin   ();

use Padre::Wx::Dialog::ExperimentalPerlFilter ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';

#####################################################################
# Padre::Plugin Methods

sub padre_interfaces {
	'Padre::Plugin' => 0.80;
}

sub plugin_name {
	'Filter through Perl (experimental)';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'Run...' => sub { $self->show },

		# 'Another Menu Entry' => sub { $self->about },
		# 'A Sub-Menu...' => [
		#     'Sub-Menu Entry' => sub { $self->about },
		# ],
	];
}

#####################################################################
# Custom methods

sub show {
	my $self = shift;

	Padre::Wx::Dialog::ExperimentalPerlFilter->new($self->main)->show;

	return 1;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::ExperimentalPerlFilter - My personal plugin

=head1 DESCRIPTION

This is your personal plugin. Update it to fit your needs. And if it
does interesting stuff, please consider sharing it on CPAN!

=head1 COPYRIGHT & LICENSE

Currently it's copyright (c) 2008-2009 The Padre develoment team as
listed in Padre.pm... But update it and it will become Copyright (c) you
C<< you@your-domain.com> >>! How exciting! :-)

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
