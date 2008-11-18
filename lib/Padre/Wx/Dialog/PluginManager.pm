package Padre::Wx::Dialog::PluginManager;
use strict;
use warnings;

use Padre::Wx         ();
use Padre::Wx::Dialog ();
use Wx::Locale        qw(:default);

our $VERSION = '0.17';

sub get_layout {
	my ($plugins) = @_;
	$plugins ||= {};

	my @layout;
	foreach my $module (sort keys %$plugins) {
		push @layout,
			[
				['Wx::StaticText', undef, $module],
				['Wx::Button',    "able_$module", 
					($plugins->{$module}{enabled} ? gettext('Disable') : gettext('Enable')) ],
				['Wx::Button',    "pref_$module", gettext('Preferences') ],
			];
	}
	
	push @layout,
		[
			['Wx::Button',     'ok',     Wx::wxID_OK],
			[],
			[],
		];

	return \@layout;
}

sub dialog {
	my ($class, $main) = @_;

	my $config = Padre->ide->config;
	my @plugins = sort keys %{ $config->{plugins} };

	my $layout = get_layout( $config->{plugins} );
	my $dialog = Padre::Wx::Dialog->new(
		parent   => $main,
		title    => gettext('Plugin Manager'),
		layout   => $layout,
		width    => [300, 100, 100],
	);
	foreach my $module (@plugins) {
		Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{"pref_$module"}, sub { _pref(@_, $module)} );
		Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{"able_$module"}, sub { _able(@_, $module)} );
		if (not $config->{plugins}{$module}{enabled}) {
			$dialog->{_widgets_}{"pref_$module"}->Disable;
		}
	}

	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{ok},      sub { $dialog->EndModal(Wx::wxID_OK) } );
	$dialog->{_widgets_}{ok}->SetDefault;

	$dialog->{_widgets_}{ok}->SetFocus;

	return $dialog;
}

sub _pref {
	my ($self, $event, $module) = @_;
	#$self->{_widgets_}{"pref_$module"}
	
	#print "$self\n";
}

sub _able {
	my ($self, $event, $module) = @_;
	
	my $config = Padre->ide->config;
	if ($config->{plugins}{$module}{enabled}) {
		# disable plugin
		$config->{plugins}{$module}{enabled} = 0;
		$self->{_widgets_}{"able_$module"}->SetLabel(gettext('Enable'));
		$self->{_widgets_}{"pref_$module"}->Disable;
	} else {
		# enable plugin
		$config->{plugins}{$module}{enabled} = 1;
		$self->{_widgets_}{"able_$module"}->SetLabel(gettext('Disable'));
		$self->{_widgets_}{"pref_$module"}->Enable;
	}
	#print "$self\n";
}


sub show {
	my ($class, $main) = @_;

	my $dialog   = $class->dialog($main);
	return if not $dialog->show_modal;
	
	my $data = $dialog->get_data;
	$dialog->Destroy;

	return;
}


1;
