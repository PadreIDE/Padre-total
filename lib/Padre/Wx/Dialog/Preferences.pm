package Padre::Wx::Dialog::Preferences;

use 5.008;
use strict;
use warnings;

use Padre::Wx         ();
use Padre::Wx::Dialog ();
use Wx::Locale        qw(:default);

our $VERSION = '0.19';

sub get_layout {
	my ($config, $main_startup, $editor_autoindent) = @_;

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
			[ 'Wx::StaticText', undef,              gettext('Guess from current document')],
			[ 'Wx::Button',     '_guess_',          gettext('Guess')     ],
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
			[ 'Wx::StaticText', undef,              gettext('Autoindent:')],
			[ 'Wx::Choice',     'editor_autoindent',    $editor_autoindent],
		],
		[
			[ 'Wx::StaticText', undef,              gettext('Default word wrap on for each file')],
			['Wx::CheckBox',    'editor_use_wordwrap', '',
				($config->{editor_use_wordwrap} ? 1 : 0) ],
		],
		[
			[ 'Wx::Button',     '_ok_',           Wx::wxID_OK     ],
			[ 'Wx::Button',     '_cancel_',       Wx::wxID_CANCEL ],
		],
	];
}

sub dialog {
	my ($class, $win, $main_startup, $editor_autoindent) = @_;

	my $config = Padre->ide->config;
	my $layout = get_layout($config, $main_startup, $editor_autoindent);
	my $dialog = Padre::Wx::Dialog->new(
		parent => $win,
		title  => gettext("Preferences"),
		layout => $layout,
		width  => [250, 200],
	);

	$dialog->{_widgets_}{editor_tabwidth}->SetFocus;
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_ok_},     sub { $dialog->EndModal(Wx::wxID_OK) } );
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_cancel_}, sub { $dialog->EndModal(Wx::wxID_CANCEL) } );

	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_guess_},  sub { $class->guess_indentation_settings($dialog) } );

	$dialog->{_widgets_}{_ok_}->SetDefault;
	
	return $dialog;
}

sub guess_indentation_settings {
	my $class  = shift;
	my $dialog = shift;
	my $doc    = Padre::Documents->current;

	require Text::FindIndent;
	my $indentation = Text::FindIndent->parse($doc->text_get);

	# TODO: Padre can't do mixed tab/space indentation (i.e. tab-compressed indentation) yet

	if ($indentation =~ /^t\d+/) { # we only do ONE tab
		$dialog->{_widgets_}{editor_use_tabs}->SetValue(1);
		$dialog->{_widgets_}{editor_tabwidth}->SetValue(8);
	}
	elsif ($indentation =~ /^[sm](\d+)/) {
		# TODO: as mentioned above, the "m"/mixed case needs to eventually be separate
		$dialog->{_widgets_}{editor_use_tabs}->SetValue(0);
		$dialog->{_widgets_}{editor_tabwidth}->SetValue($1);
	}
	else {
		# fallback
		$dialog->{_widgets_}{editor_use_tabs}->SetValue(0);
		$dialog->{_widgets_}{editor_tabwidth}->SetValue(8);
	}

}


sub run {
	my ( $class, $win ) = @_;

	my $config = Padre->ide->config;

	my @main_startup = (
		$config->{main_startup},
		grep { $_ ne $config->{main_startup} } qw( new nothing last )
	);
	my @editor_autoindent = (
		$config->{editor_autoindent},
		grep { $_ ne $config->{editor_autoindent} } qw( no same_level deep )
	);

	my $dialog = $class->dialog( $win, \@main_startup, \@editor_autoindent );
	return if not $dialog->show_modal;

	my $data = $dialog->get_data;

	foreach my $f (qw(pod_maxlist pod_minlist editor_tabwidth)) {
		$config->{$f} = $data->{$f};
	}
	foreach my $f (qw(editor_use_tabs editor_use_wordwrap)) {
		$config->{$f} = $data->{$f} ? 1 :0;
	}

	$config->{main_startup}        = $main_startup[ $data->{main_startup} ];
	$config->{editor_autoindent}   = $editor_autoindent[ $data->{editor_autoindent} ];

	return;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
