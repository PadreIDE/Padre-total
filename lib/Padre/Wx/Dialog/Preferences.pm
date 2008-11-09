package Padre::Wx::Dialog::Preferences;

use 5.008;
use strict;
use warnings;

use Padre::Wx         ();
use Padre::Wx::Dialog ();
use Wx::Locale        qw(:default);

our $VERSION = '0.16';

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

sub dialog {
	my ($class, $win, $main_startup) = @_;

	my $config = Padre->ide->config;
	my $layout = get_layout($config, $main_startup);
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
	
	return $dialog;
}



sub run {
	my ( $class, $win ) = @_;

	my $config = Padre->ide->config;

	my @main_startup = (
		$config->{main_startup},
		grep { $_ ne $config->{main_startup} } qw( new nothing last )
	);

	my $dialog = $class->dialog( $win, \@main_startup );
	return if not $dialog->show_modal;

	my $data = $dialog->get_data;

	foreach my $f (qw(pod_maxlist pod_minlist editor_tabwidth)) {
		$config->{$f} = $data->{$f};
	}
	foreach my $f (qw(editor_use_tabs)) {
		$config->{$f} = $data->{$f} ? 1 :0;
	}
	$config->{main_startup}    = $main_startup[ $data->{main_startup} ];

	return;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
