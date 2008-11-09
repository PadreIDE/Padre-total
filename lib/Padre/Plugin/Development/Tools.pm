package Padre::Plugin::Development::Tools;
use strict;
use warnings;


our $VERSION = '0.16';

use Padre::Wx ();

use Data::Dumper   ();

=head1 NAME

Padre::Plugin::Development::Tools - tools used by the Padre developers

=cut

# TODO fix this
# we need to create anonymous subs in order to makes
# sure reloading the module changes the call as well
# A better to replace the whole Plugins/ menu when we
# reload plugins.
my @menu = (
	['About',          sub {about(@_)}          ],
	['Show %INC',      sub {show_inc(@_)}       ],
	['Reload plugins', sub {reload_plugins(@_)} ],
	['Info',           sub {info(@_)} ],
);
sub menu {
    my ($self) = @_;
	return @menu;
}

sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Development::Tools");
	$about->SetDescription(
		"A set of unrelated tools used by the Padre developers\n" .
		"Some of these might end up in core Padre or in oter plugins"
	);
	#$about->SetVersion($Padre::VERSION);
	Wx::AboutBox( $about );
	return;
}

sub info {
	my ($main) = @_;
	my $doc = Padre::Documents->current;
	if (not $doc) {
		$main->message( 'No file is open', 'Info' );

		return;
	}
	my $msg = '';
	$msg   .= "Doc: $doc\n";
	$main->message( $msg, 'Info' );

	return;
}

sub show_inc {
	my ($main) = @_;

	Wx::MessageBox( Data::Dumper::Dumper(\%INC), '%INC', Wx::wxOK|Wx::wxCENTRE, $main );
	
}

sub reload_plugins {
	my ($main) = @_;

	my $manager = Padre->ide->plugin_manager;
	my $plugins = $manager->plugins;
	%$plugins = ();
#	foreach my $k (keys %INC) {
#		if ($k =~ m{^Padre/Plugin/}) {
#			print "$k\n";
#			delete $INC{$k};
#		}
#	}
	delete $INC{'Padre/Plugin/Development/Tools.pm'};
	$manager->load_plugins;

	Wx::MessageBox( "done", "done", Wx::wxOK|Wx::wxCENTRE, $main );
	
	return;
}



1;
