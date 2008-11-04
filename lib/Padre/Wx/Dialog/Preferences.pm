package Padre::Wx::Dialog::Preferences;

use 5.008;
use strict;
use warnings;

use Padre::Wx         ();
use Padre::Wx::Dialog ();
use Wx::Locale        qw(:default);

our $VERSION = '0.15';

sub get_layout {
	my ($config, $main_startup) = @_;

	return [
		[
			[],
			['Wx::CheckBox',    'editor_use_tabs', gettext('Use Tabs'),    ($config->{editor_use_tabs} ? 1 : 0) ],
		],
		[
			[ 'Wx::StaticText', undef,              gettext('TAB display size (in spaces)')],
			[ 'Wx::TextCtrl',   'editor_tabwidth',	$config->{editor_tabwidth}],
		],
		[
			[ 'Wx::StaticText', undef,              gettext('Max number of modules')],
			[ 'Wx::TextCtrl',   'pod_maxlist',		$config->{pod_maxlist}],
		],
		[
			[ 'Wx::StaticText', undef,              gettext('Min number of modules')],
			[ 'Wx::TextCtrl',   'pod_minlist', 	     $config->{pod_minlist}],
		],
		[
			[ 'Wx::StaticText', undef,              gettext('Open files:')],
			[ 'Wx::Choice',     'main_startup',    $main_startup],
		],
		[
			[ 'Wx::Button',     '_ok_',           Wx::wxID_OK     ],
			[ 'Wx::Button',     '_cancel_',       Wx::wxID_CANCEL ],
		],
	];
}

sub run {
	my ( $class, $win, $config ) = @_;

	my @main_startup = (
		$config->{main_startup},
		grep { $_ ne $config->{main_startup} } qw( new nothing last )
	);

	my $layout = get_layout($config, \@main_startup);
	my $dialog = Padre::Wx::Dialog->new(
		parent => $win,
		title  => gettext("Preferences"),
		layout => $layout,
		width  => [250, 200],
	);

	$dialog->{_widgets_}{editor_tabwidth}->SetFocus;
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_ok_},     sub { $dialog->EndModal(Wx::wxID_OK) } );
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_cancel_}, sub { $dialog->EndModal(Wx::wxID_CANCEL) } );

	$dialog->{_widgets_}{_ok_}->SetDefault;
	if ($dialog->ShowModal == Wx::wxID_CANCEL) {
		return;
	}

	my $data = $dialog->get_data;

	foreach my $f (qw(editor_use_tabs pod_maxlist pod_minlist editor_tabwidth)) {
		$config->{$f} = $data->{$f};
	}
	$config->{main_startup}    = $main_startup[ $data->{choice} ];

	return;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
