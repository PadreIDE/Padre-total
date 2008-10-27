package Padre::Wx::Preferences;

use 5.008;
use strict;
use warnings;

use Padre::Wx         ();
use Padre::Wx::Dialog ();

our $VERSION = '0.13';

sub get_layout {
	my ($config, $values) = @_;

	return [
		[
			[],
			['Wx::CheckBox',    'editor_use_tabs', 'Use Tabs',    ($config->{editor_use_tabs} ? 1 : 0) ],
		],
		[
			[ 'Wx::StaticText', undef,              'TAB display size (in spaces)'],
			[ 'Wx::TextCtrl',   'editor_tabwidth',	$config->{editor_tabwidth}],
		],
		[
			[ 'Wx::StaticText', undef,              'Max number of modules'],
			[ 'Wx::TextCtrl',   'pod_maxlist',		$config->{pod_maxlist}],
		],
		[
			[ 'Wx::StaticText', undef,              'Min number of modules'],
			[ 'Wx::TextCtrl',   'pod_minlist', 	     $config->{pod_minlist}],
		],
		[
			[ 'Wx::StaticText', undef,              'Open files:'],
			[ 'Wx::Choice',     'choice',    $values],
		],
		[
			[ 'Wx::Button',     '_ok_',           Wx::wxID_OK     ],
			[ 'Wx::Button',     '_cancel_',       Wx::wxID_CANCEL ],
		],
	];
}

sub run {
	my ( $class, $win, $config ) = @_;

	my @values = (
		$config->{main_startup},
		grep { $_ ne $config->{main_startup} } qw( new nothing last )
	);

	my $dialog = Wx::Dialog->new( $win, -1, "Preferences", [-1, -1], [450, 170], Wx::wxDEFAULT_FRAME_STYLE);

	my $layout = get_layout($config, \@values);
	Padre::Wx::Dialog::build_layout($dialog, $layout, [250, 200]);
	$dialog->{editor_tabwidth}->SetFocus;
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_ok_},     sub { $dialog->EndModal(Wx::wxID_OK) } );
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_cancel_}, sub { $dialog->EndModal(Wx::wxID_CANCEL) } );

	$dialog->{_ok_}->SetDefault;
	if ($dialog->ShowModal == Wx::wxID_CANCEL) {
		return;
	}

	my $data = Padre::Wx::Dialog::get_data_from( $dialog, get_layout() );

	foreach my $f (qw(editor_use_tabs pod_maxlist pod_minlist editor_tabwidth)) {
		$config->{$f} = $data->{$f};
	}
	$config->{main_startup}    = $values[ $data->{choice} ];

	return;
}

1;
