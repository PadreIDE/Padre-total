package Padre::Wx::ModuleStartDialog;

use 5.008;
use strict;
use warnings;
use Data::Dumper qw(Dumper);
use Cwd          ();

# Module::Start widget of Padre

use Padre::Wx         ();
use Padre::Wx::Dialog ();

our $VERSION = '0.14';

sub on_start {
	my $main   = shift;
	my $config = Padre->ide->config;
	__PACKAGE__->dialog( $main, $config, { } );
}

sub dialog {
	my ( $class, $win, $config, $args) = @_;

	my $dialog = Wx::Dialog->new( $win, -1, "Module Start", [-1, -1], [310, 210]);

	my $layout = get_layout($config);
	Padre::Wx::Dialog::build_layout($dialog, $layout, [100, 200], [5, 5]);

	$dialog->{_ok_}->SetDefault;
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_ok_},      \&ok_clicked      );
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_cancel_},  \&cancel_clicked  );

        $dialog->{_license_choice_}->SetValue('perl');

	$dialog->{_module_name_}->SetFocus;
	$dialog->Show(1);

	return;
}

sub get_layout {
	my ($config) = @_;

	my @builders = ('Module::Build', 'ExtUtils::MakeMaker'); #, 'Module::Install');
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
			[ 'Wx::Button',     '_ok_',           Wx::wxID_OK     ],
			[ 'Wx::Button',     '_cancel_',       Wx::wxID_CANCEL ],
		],
	);
	return \@layout;
}


sub cancel_clicked {
	my ($dialog, $event) = @_;

	$dialog->Destroy;

	return;
}

sub ok_clicked {
	my ($dialog, $event) = @_;

	my $data = Padre::Wx::Dialog::get_data_from( $dialog, get_layout() );
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
	Wx::MessageBox("$data->{_module_name_} apparantly created.", "Done", Wx::wxOK, $main_window);

	return;
}


1;
