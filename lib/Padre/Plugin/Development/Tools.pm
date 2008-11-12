package Padre::Plugin::Development::Tools;
use strict;
use warnings;


our $VERSION = '0.16';

use Padre::Wx ();

use Wx ':everything';
use Wx::Menu ();
use Wx::Locale qw(:default);

use File::Basename ();
use File::Spec     ();
use Data::Dumper   ();
use Padre::Util ();
use Module::Refresh;

=head1 NAME

Padre::Plugin::Development::Tools - tools used by the Padre developers

=cut

# TODO fix this
# we need to create anonymous subs in order to makes
# sure reloading the module changes the call as well
# A better to replace the whole Plugins/ menu when we
# reload plugins.
my @menu = (
	['Reload All Plugins', \&reload_plugins     ],
    ['Test A Plugin From Local Dir', \&test_a_plugin],
	['Show %INC',      sub {show_inc(@_)}       ],
	['Info',           sub {info(@_)}           ],
	['About',          sub {about(@_)}          ],
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
    my ( $self ) = @_;

    _reload_x_plugins( $self );
    
    Wx::MessageBox( 'done', 'done', Wx::wxOK|Wx::wxCENTRE, $self );
}

sub test_a_plugin {
    my ( $self ) = @_;
    
    my $manager = Padre->ide->plugin_manager;
    my $plugin_config = $manager->plugin_config('Development::Tools');
    my $last_filename = $plugin_config->{last_filename};
    $last_filename  ||= $self->selected_filename;
    my $default_dir;
    if ($last_filename) {
        $default_dir = File::Basename::dirname($last_filename);
    }
    my $dialog = Wx::FileDialog->new(
        $self,
        'Open file',
        $default_dir,
        "",
        "*.*",
        Wx::wxFD_OPEN,
    );
    unless ( Padre::Util::WIN32 ) {
        $dialog->SetWildcard("*");
    }
    if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
        return;
    }
    my $filename = $dialog->GetFilename;
    $default_dir = $dialog->GetDirectory;
    
    my $file = File::Spec->catfile($default_dir, $filename);
    
    # save into plugin for next time
    $plugin_config->{last_filename} = $file;
    
    $filename    =~ s/\.pm$//; # remove last .pm
    $filename    =~ s/[\\\/]/\:\:/;
    $default_dir =~ s/Padre[\\\/]Plugin([\\\/]|$)//;
    
    unshift @INC, $default_dir unless ($INC[0] eq $default_dir);
    my $plugins = Padre->ide->plugin_manager->plugins;
    $plugins->{$filename} = "Padre::Plugin::$filename";
    eval { require $file; 1 }; # load for Module::Refresh
    return $self->error( $@ ) if ( $@ );
    
    # reload all means rebuild the 'Plugins' menu
    _reload_x_plugins( $self, 'all' );
    
    Wx::MessageBox( 'done', 'done', Wx::wxOK|Wx::wxCENTRE, $self );
}

sub _reload_x_plugins {
    my ( $self ) = @_;
    
    my $refresher = new Module::Refresh;

    my %plugins = %{ Padre->ide->plugin_manager->plugins };
    foreach my $name ( sort keys %plugins ) {
        if ( $name eq 'Development::Tools' ) {
			next; # no warnings; # DO not reload itself
        }
        # reload the module
        my $file_in_INC = "Padre/Plugin/${name}.pm";
        $file_in_INC =~ s/\:\:/\//;
        $refresher->refresh_module($file_in_INC);
    }
    
    # re-create menu, # coped from Padre::Wx::Menu
    my $plugin_menu = $self->{menu}->get_plugin_menu();
    my $plugin_menu_place = $self->{menu}->{wx}->FindMenu( gettext("Pl&ugins") );
    $self->{menu}->{wx}->Replace( $plugin_menu_place, $plugin_menu, gettext("Pl&ugins") );
    
    $self->{menu}->refresh;
}

1;
