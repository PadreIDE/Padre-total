package Padre::Wx::ModuleStartDialog;

use 5.008;
use strict;
use warnings;

# Module::Start widget of Padre

use Wx           qw(wxOK wxID_OK wxVERTICAL wxHORIZONTAL wxEXPAND);
use Wx::Event    qw( EVT_BUTTON EVT_CHECKBOX );
use Data::Dumper qw(Dumper);
use Cwd          ();

our $VERSION = '0.12';

sub on_start {
	my $main   = shift;
	my $config = Padre->ide->config;

	__PACKAGE__->dialog( $main, $config, { } );
}

sub dialog {
	my ( $class, $win, $config, $args) = @_;

	my $dialog = Wx::Dialog->new( $win, -1, "Module Start", [-1, -1], [300, 220]);

	my $layout = get_layout($config);
	build_layout($dialog, $layout, [100, 200]);

	$dialog->{_ok_}->SetDefault;
	EVT_BUTTON( $dialog, $dialog->{_ok_},      \&ok_clicked      );
	EVT_BUTTON( $dialog, $dialog->{_cancel_},  \&cancel_clicked  );

	$dialog->{_module_name_}->SetFocus;
	$dialog->Show(1);

	return;
}

sub get_layout {
	my ($config) = @_;

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
			[ 'Wx::TextCtrl',   '_author_name_',    '', ($config->{module_start}{author_name} || '') ],
		],
		[
			[ 'Wx::StaticText', undef,              'Email:'],
			[ 'Wx::TextCtrl',   '_email_',          '', ($config->{module_start}{email} || '') ],
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
				# it seems we cannot set the default directory and 
				# we still have to set this directory in order to get anything back in
				# GetPath
				$widget->SetPath(Cwd::cwd());
			} elsif ($class eq 'Wx::TextCtrl') {
				my $default = shift @params;
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, [$width->[$j], -1], @params );
				if (defined $default) {
					$widget->SetValue($default);
				}
			} elsif ($class eq 'Wx::CheckBox') {
				my $default = shift @params;
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, [$width->[$j], -1], @params );
				$widget->SetValue($default);
			} else {
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, [$width->[$j], -1], @params );
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
	print Dumper $data;

	my $config = Padre->ide->config;
	$config->{module_start}{author_name} = $data->{_author_name_};
	$config->{module_start}{email}       = $data->{_email_};

	my $main_window = Padre->ide->wx->main_window;

	# TODO improve input validation !
	my @fields = qw(_module_name_ _author_name_ _email_ _builder_choice_ _license_choice_);
	foreach my $f (@fields) {
		if (not $data->{$f}) {
			Wx::MessageBox("Field $f was missing. Module not created.", "missing field", Wx::wxOK, $main_window);
			return;
		}
	}

	my $pwd = Cwd::cwd();
	chdir $data->{_directory_};
	require Module::Starter::App;
	@ARGV = ('--module',   $data->{_module_name_},
	         '--author',   $data->{_author_name_},
	         '--email',    $data->{_email_},
	         '--builder',  $data->{_builder_choice_},
	         '--license',  $data->{_license_choice_},
	        );
	Module::Starter::App->run;
	@ARGV = ();
	chdir $pwd;
	Wx::MessageBox("$data->{_module_name_} apperantly created.", "Done", Wx::wxOK, $main_window);

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
