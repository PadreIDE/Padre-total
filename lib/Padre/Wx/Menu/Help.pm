package Padre::Wx::Menu::Help;

use 5.008;
use strict;
use warnings;
use Wx ();

our $VERSION = '0.10';
our @ISA     = 'Wx::Menu';

sub help {
	my $main = shift;
	unless ( $main->{help} ) {
		$main->{help} = Padre::Pod::Frame->new;
		my $module = Padre::DB->get_last_pod || 'Padre';
		if ( $module ) {
			$main->{help}->{html}->display($module);
		}
	}
	$main->{help}->SetFocus;
	$main->{help}->Show(1);
	return;

}

sub about {
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre");
	$about->SetDescription(
		"Perl Application Development and Refactoring Environment\n\n" .
		"Based on Wx.pm $Wx::VERSION and " . Wx::wxVERSION_STRING . "\n" .
		"Config at " . Padre->ide->config_dir . "\n"
	);
	$about->SetVersion($Padre::VERSION);
	$about->SetCopyright("Copyright 2008 Gabor Szabo");
	# Only Unix/GTK native about box supports websites
	if ( Padre::Util::UNIX ) {
		$about->SetWebSite("http://padre.perlide.org/");
	}
	$about->AddDeveloper("Gabor Szabo");
	$about->AddDeveloper("Adam Kennedy");
	Wx::AboutBox( $about );
	return;
}

1;
