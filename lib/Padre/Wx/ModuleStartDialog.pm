package Padre::Wx::ModuleStartDialog;

use 5.008;
use strict;
use warnings;

# Module::Start widget of Padre

use Wx        ();
use Wx::Event qw{ EVT_BUTTON EVT_CHECKBOX };
use Data::Dumper qw(Dumper);
use Cwd       ();

our $VERSION = '0.10';

sub on_start {
	my $main   = shift;
	my $config = Padre->ide->config;

	__PACKAGE__->dialog( $main, $config, { } );
}

sub dialog {
	my ( $class, $win, $config, $args) = @_;

	my $dialog = Wx::Dialog->new( $win, -1, "Module Start", [-1, -1], [300, 220]);

	my $layout = get_layout();
	build_layout($dialog, $layout, [100, 200]);

	$dialog->{_ok_}->SetDefault;
	EVT_BUTTON( $dialog, $dialog->{_ok_},      \&ok_clicked      );
	EVT_BUTTON( $dialog, $dialog->{_cancel_},  \&cancel_clicked  );

	$dialog->{_module_name_}->SetFocus;
	$dialog->Show(1);

	return;
}

sub get_layout {

	my @builders = ('Module::Build', 'ExtUtils::MakeMaker', 'Module::Install');
	my @licenses = qw(apache artistic artistic_2 bsd gpl lgpl mit mozilla open_source perl restrictive unrestricted);
	# licenses list taken from 
	# http://search.cpan.org/dist/Module-Build/lib/Module/Build/API.pod
	# even though it should be in http://module-build.sourceforge.net/META-spec.html
	# and we should fetch it from Module::Start or maybe Software::License

	my @layout = (
		[
			[ 'Wx::StaticText', undef,              'Module Name:'],
			[ 'Wx::TextCtrl',   '_module_name_',    ''],
		],
		[
			[ 'Wx::StaticText', undef,              'Author:'],
			[ 'Wx::TextCtrl',   '_author_name_',    ''],
		],
		[
			[ 'Wx::StaticText', undef,              'Email:'],
			[ 'Wx::TextCtrl',   '_email_',          ''],
		],
		[
			[ 'Wx::StaticText', undef,              'Builder:'],
			[ 'Wx::ComboBox',   '_builder_choice_', '',       \@builders],
		],
		[
			[ 'Wx::StaticText', undef,              'License:'],
			[ 'Wx::ComboBox',   '_license_choice_', '',       \@licenses],
		],
		[
			[ 'Wx::StaticText',      undef,         'Parent Directory:'],
			[ 'Wx::DirPickerCtrl',   '_directory_', '',   'Pick parent directory'],
		],
		[
			[ 'Wx::Button',     '_ok_',           Wx::wxID_OK],
			[ 'Wx::Button',     '_cancel_',       Wx::wxID_CANCEL],
		]
	);
	return \@layout;
}


sub build_layout {
	my ($dialog, $layout, $width) = @_;

	my $box  = Wx::BoxSizer->new( Wx::wxVERTICAL );

	foreach my $i (0..@$layout-1) {
		my $row = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
		$box->Add($row);
		foreach my $j (0..@{$layout->[$i]}-1) {
			if (not @{ $layout->[$i][$j] } ) {  # [] means Expand
				$row->Add($width->[$j], 0, 0, Wx::wxEXPAND, 0);
				next;
			}
			my ($class, $name, $arg, @params) = @{ $layout->[$i][$j] };

			my $widget;
			if ($class eq 'Wx::Button') {
				my ($first, $second) = $arg =~ /[a-zA-Z]/ ? (-1, $arg) : ($arg, '');
				$widget = $class->new( $dialog, $first, $second);
			} elsif ($class eq 'Wx::DirPickerCtrl') {
				my $title = shift(@params) || '';
				$widget = $class->new( $dialog, -1, $arg, $title, Wx::wxDefaultPosition, [$width->[$j], -1], @params );
			} else {
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, [$width->[$j], -1], @params );
			}

			# it seems we cannot set the default directory and 
			# we still have to set this directory in order to get anything back in
			# GetPath
			if ($class eq 'Wx::DirPickerCtrl') {
				$widget->SetPath(Cwd::cwd());
			} elsif ($class eq 'Wx::CheckBox') {
				$widget->SetValue(shift @params);
			}

			$row->Add($widget);

			if ($name) {
				$dialog->{$name} = $widget;
			}
		}
	}

	$dialog->SetSizer($box);

	return;
}

sub cancel_clicked {
	my ($dialog, $event) = @_;

	$dialog->Destroy;

	return;
}

sub ok_clicked {
	my ($dialog, $event) = @_;

	my $data = get_data_from( $dialog, get_layout() );
	$dialog->Destroy;

	#my $config = Padre->ide->config;
	#my $main_window = Padre->ide->wx->main_window;
	print Dumper $data;

	return;
}

sub get_data_from {
	my ( $dialog, $layout ) = @_;

	my %data;
	foreach my $i (0..@$layout-1) {
		foreach my $j (0..@{$layout->[$i]}-1) {
			next if not @{ $layout->[$i][$j] }; # [] means Expand
			my ($class, $name, $arg, @params) = @{ $layout->[$i][$j] };
			if ($name) {
				next if $class eq 'Wx::Button';

				if ($class eq 'Wx::DirPickerCtrl') {
					$data{$name} = $dialog->{$name}->GetPath;
				} else {
					$data{$name} = $dialog->{$name}->GetValue;
				}
			}
		}
	}

	return \%data;
}


1;
