package Padre::Plugin::Catalyst::Outline;

use strict;
use warnings;

use Padre::Wx      ();
use Padre::Util    ('_T');
use Wx;

use base 'Wx::TreeCtrl';

our $VERSION = '0.06';


sub new {
	my $class = shift;
	my $plugin  = shift;
	
	my $self  = $class->SUPER::new(
		Padre::Current->main->right,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTR_HIDE_ROOT | Wx::wxTR_SINGLE | Wx::wxTR_HAS_BUTTONS | Wx::wxTR_LINES_AT_ROOT
	);
	$self->SetIndent(10);
	$self->{force_next} = 0;

	Wx::Event::EVT_COMMAND_SET_FOCUS(
		$self, $self,
		sub {
#			$self->on_tree_item_set_focus( $_[1] );
		},
	);

	# Double-click a function name
	Wx::Event::EVT_TREE_ITEM_ACTIVATED(
		$self, $self,
		sub {
#			$self->on_tree_item_activated( $_[1] );
		}
	);

#	$self->Hide;
    $self->Show;

	return $self;
}

sub gettext_label {
	_T('Catalyst');
}


1;

