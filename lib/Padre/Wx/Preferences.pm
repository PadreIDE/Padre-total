package Padre::Wx::Preferences;

use 5.008;
use strict;
use warnings;
use Wx        qw(wxID_OK wxID_CANCEL wxDEFAULT_FRAME_STYLE);
use Wx::Event qw(EVT_BUTTON);

our $VERSION = '0.10';

sub run {
	my ( $class, $win, $config ) = @_;

	my $dialog = Wx::Dialog->new( $win, -1, "Preferences", [-1, -1], [550, 200], wxDEFAULT_FRAME_STYLE);

	my $y = 10;
	my $HEIGHT = 30;

	Wx::StaticText->new( $dialog, -1, 'TAB display size (in spaces)', [10, $y], [-1, -1]);
	my $tabwidth = Wx::TextCtrl->new(
		$dialog,
		-1,
		$config->{editor_tabwidth},
		[ 300, $y ],
		[ -1, -1 ],
	);
	$tabwidth->SetFocus;

	$y += $HEIGHT;
	Wx::StaticText->new( $dialog, -1, 'Max number of modules', [10, $y], [-1, -1]);
	my $max = Wx::TextCtrl->new( $dialog, -1, $config->{pod_maxlist}, [300, $y] , [-1, -1]);

	$y += $HEIGHT;
	Wx::StaticText->new( $dialog, -1, 'Min number of modules', [10, $y], [-1, -1]);
	my $min = Wx::TextCtrl->new( $dialog, -1, $config->{pod_minlist}, [300, $y] , [-1, -1]);

	$y += $HEIGHT;
	Wx::StaticText->new( $dialog, -1, 'Open files:', [10, $y], [-1, -1]);
	my @values = (
		$config->{main_startup},
		grep { $_ ne $config->{main_startup} } qw( new nothing last )
	);
	my $choice = Wx::Choice->new( $dialog, -1, [300, $y], [-1, -1], \@values );

	$y += $HEIGHT;
	my $ok     = Wx::Button->new( $dialog, wxID_OK,     '', [10,  $y] );
	my $cancel = Wx::Button->new( $dialog, wxID_CANCEL, '', [120, $y], $ok->GetSize );
	EVT_BUTTON( $dialog, $ok,     sub { $dialog->EndModal(wxID_OK) } );
	EVT_BUTTON( $dialog, $cancel, sub { $dialog->EndModal(wxID_CANCEL) } );
	$ok->SetDefault;
	if ($dialog->ShowModal == wxID_CANCEL) {
		return;
	}
	$config->{pod_maxlist}     = $max->GetValue;
	$config->{pod_minlist}     = $min->GetValue;
	$config->{editor_tabwidth} = $tabwidth->GetValue;
	$config->{main_startup}    = $values[ $choice->GetSelection ];

	return;
}

1;
