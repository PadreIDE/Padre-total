package Padre::Wx::Dialog::Preferences::PHP;

use warnings;
use strict;
use 5.008;

use Padre::Wx::Dialog::Preferences ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Wx::Dialog::Preferences';

sub panel {
	my $self     = shift;
	my $treebook = shift;

	my $config = Padre->ide->config;

	my $table = [

		#		[   [   'Wx::CheckBox', 'editor_wordwrap', ( $config->editor_wordwrap ? 1 : 0 ),
		#				Wx::gettext('Default word wrap on for each file')
		#			],
		#			[]
		#		],
		[   [ 'Wx::StaticText', undef,     Wx::gettext('PHP interpreter:') ],
			[ 'Wx::TextCtrl',   'php_cmd', $config->php_cmd ]
		],
		[   [ 'Wx::StaticText', undef,                          Wx::gettext('PHP interpreter arguments:') ],
			[ 'Wx::TextCtrl',   'php_interpreter_args_default', $config->php_interpreter_args_default ]
		],
	];

	my $panel = $self->_new_panel($treebook);
	$self->fill_panel_by_table( $panel, $table );

	return $panel;
}

sub save {
	my $self = shift;
	my $data = shift;

	my $config = Padre->ide->config;

	$config->set(
		'php_cmd',
		$data->{php_cmd}
	);

	$config->set(
		'php_interpreter_args_default',
		$data->{php_interpreter_args_default}
	);

}



1;
__END__

=head1 NAME

Padre::Plugin::PHP - L<Padre> and PHP

=head1 AUTHOR

Sebastian Willing

=head1 COPYRIGHT & LICENSE

Copyright 2009 Gabor Szabo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
