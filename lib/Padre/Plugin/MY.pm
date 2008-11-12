package Padre::Plugin::MY;
use strict;
use warnings;

our $VERSION = '0.01';

sub menu {
	return ( 
		['About'          => \&about],

# to get another menu item comment out the following line
# and implement appropriate function		
#		 ['Do something quick'   => \&do_something_quick],
		
# to have deeper levels in the menu comment out the following
# 4 lines and implement the appropriate function
#		[ 'Deep' => [
#				['Do something substantial'   => \&do_something_substantial],
#			],
#		],
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

	my $path = File::Spec->catfile(Padre->ide->config_dir, 'plugins', 'Padre', 'Plugin', 'MY.pm');
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("MY Plugin");
	$about->SetDescription(
		"In order to make it easier to add small snippets of code\n" .
		"to be executed in Padre, to write your own plugin\n" .
		"We provide this special plugin called MY\n" .
		"It is located in your configuration directory at\n" .
		"$path\n" .
		"\n" .
		"Open it with any Padre and you'll see an explanation on how to add items"
	);
	Wx::AboutBox( $about );
	return;
}


1;
