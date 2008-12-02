package Padre::Wx::Menu::Help;

use 5.008;
use strict;
use warnings;

use Padre::Wx ();
use Padre::Util;
use Wx::Locale qw(:default);

our $VERSION = '0.20';
#our @ISA     = 'Wx::Menu';
sub new { return bless {}, shift };

sub help {
	my $self = shift;
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
	my $self = shift;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre");
	$about->SetDescription(
		"Perl Application Development and Refactoring Environment\n\n" .
		"Based on Wx.pm $Wx::VERSION and " . Wx::wxVERSION_STRING . "\n" .
		"Config at " . Padre->ide->config_dir . "\n"
	);
	$about->SetVersion($Padre::VERSION);
	$about->SetCopyright(gettext("Copyright 2008 Gabor Szabo"));
	# Only Unix/GTK native about box supports websites
	if ( Padre::Util::UNIX ) {
		$about->SetWebSite("http://padre.perlide.org/");
	}
	$about->AddDeveloper("Adam Kennedy");
	$about->AddDeveloper("Brian Cassidy");
	$about->AddDeveloper("Chris Dolan");
	$about->AddDeveloper("Fayland Lam");
	$about->AddDeveloper("Gabor Szabo");
	$about->AddDeveloper("Heiko Jansen");
	$about->AddDeveloper("Jerome Quelin");
	$about->AddDeveloper("Kaare Rasmussen");
	$about->AddDeveloper("Keedi Kim");
	$about->AddDeveloper("Max Maischein");
	$about->AddDeveloper("Patrick Donelan");
	$about->AddDeveloper("Steffen Mueller");

	$about->AddTranslator("German - Heiko Jansen");
	$about->AddTranslator("French - Jerome Quelin");
	$about->AddTranslator("Hebrew - Omer Zak");
	$about->AddTranslator("Hungarian - Gyorgy Pasztor");
	$about->AddTranslator("Italian - Simone Blandino");
	$about->AddTranslator("Korean - Keedi Kim");


	Wx::AboutBox( $about );
	return;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
