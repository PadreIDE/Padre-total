package Padre::Plugin::MY;

use strict;
use warnings;

our $VERSION = '0.17';

sub menu_name { 'My Plugin' }

sub menu {
	return ( 
		['About' => \&about],

		# To get another menu item comment out the following line
		# and implement appropriate function		
		# ['Do Something Quick'  => \&do_something_quick],
		
		# To have deeper levels in the menu comment out the following
		# 4 lines and implement the appropriate function
		#     [ 'Deep' => [
		#         [ 'Do something substantial' => \&do_something_substantial ],
		#     ],
		# ],
	);
}

#sub do_something_quick {
#	my ($main) = @_;
#}
#
#sub do_something_substantial {
#	my ($main) = @_;
#}

sub about {
	my ($main) = @_;

	my $path = File::Spec->catfile(
		Padre->ide->config_dir,
		qw{ plugins Padre Plugin MY.pm }
	);
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName(
		Padre::Plugin::MY->menu_name
	);
	$about->SetDescription( <<"END_MESSAGE" );
The philosophy behind Padre is that every Perl programmer
should be able to easily modify and improve their own editor.

To help you get started, we've provided you with your own plugin.

It is located in your configuration directory at:
$path
Open it with with Padre and you'll see an explanation on how to add items.
END_MESSAGE

	Wx::AboutBox( $about );
	return;
}

1;
