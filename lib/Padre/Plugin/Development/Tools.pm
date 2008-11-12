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

# TODO fix this
# we need to create anonymous subs in order to makes
# sure reloading the module changes the call as well
# A better to replace the whole Plugins/ menu when we
# reload plugins.
my @menu = (
	['Reload All Plugins', \&reload_plugins     ],
    ['Test A Plugin From Local Dir', \&test_a_plugin],
    ['Insert From File...', \&insert_from_file  ],
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

    my $refresher = new Module::Refresh;

    my %plugins = %{ Padre->ide->plugin_manager->plugins };
    foreach my $name ( sort keys %plugins ) {
    	# no warnings; # DO not reload itself
        next if ( $name eq 'Development::Tools' );

        # reload the module
        my $file_in_INC = "Padre/Plugin/${name}.pm";
        $file_in_INC =~ s/\:\:/\//;
        $refresher->refresh_module($file_in_INC);
    }
    
    # re-create menu,
    my $plugin_menu = $self->{menu}->get_plugin_menu();
    my $plugin_menu_place = $self->{menu}->{wx}->FindMenu( gettext("Pl&ugins") );
    $self->{menu}->{wx}->Replace( $plugin_menu_place, $plugin_menu, gettext("Pl&ugins") );
    
    $self->{menu}->refresh;
    
    Wx::MessageBox( 'done', 'done', Wx::wxOK|Wx::wxCENTRE, $self );
}

sub test_a_plugin {
    my ( $self ) = @_;
    
    my $manager = Padre->ide->plugin_manager;
    my $plugin_config = $manager->plugin_config('Development::Tools');
    my $last_filename = $plugin_config->{last_test_plugin_file};
    $last_filename  ||= $self->selected_filename;
    my $default_dir;
    if ($last_filename) {
        $default_dir = File::Basename::dirname($last_filename);
    }
    my $dialog = Wx::FileDialog->new(
        $self, gettext('Open file'), $default_dir, '', '*.*', Wx::wxFD_OPEN,
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
    $plugin_config->{last_test_plugin_file} = $file;
    
    $filename    =~ s/\.pm$//; # remove last .pm
    $filename    =~ s/[\\\/]/\:\:/;
    $default_dir =~ s/Padre[\\\/]Plugin([\\\/]|$)//;
    
    unshift @INC, $default_dir unless ($INC[0] eq $default_dir);
    my $plugins = Padre->ide->plugin_manager->plugins;
    $plugins->{$filename} = "Padre::Plugin::$filename";
    eval { require $file; 1 }; # load for Module::Refresh
    return $self->error( $@ ) if ( $@ );
    
    # reload all means rebuild the 'Plugins' menu
    reload_plugins( $self );
}

sub insert_from_file {
	my ( $win ) = @_;
	
	my $id  = $win->{notebook}->GetSelection;
	return if $id == -1;
	
	# popup the window
	my $last_filename = $win->selected_filename;
    my $default_dir;
    if ($last_filename) {
        $default_dir = File::Basename::dirname($last_filename);
    }
    my $dialog = Wx::FileDialog->new(
        $win, gettext('Open file'), $default_dir, '', '*.*', Wx::wxFD_OPEN,
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
    
    open( my $fh, '<', $file );
    local $/;
    my $text = <$fh>;
    close($fh);
    my $data = Wx::TextDataObject->new;
    $data->SetText($text);
    my $length = $data->GetTextLength;
	
	$win->{notebook}->GetPage($id)->ReplaceSelection('');
	my $pos = $win->{notebook}->GetPage($id)->GetCurrentPos;
	$win->{notebook}->GetPage($id)->InsertText( $pos, $text );
	$win->{notebook}->GetPage($id)->GotoPos( $pos + $length - 1 );
}

1;
__END__

=head1 NAME

Padre::Plugin::Development::Tools - tools used by the Padre developers

=head1 DESCRIPTION

=head2 Reload All Plugins

Clicking this instead of restarting the padre when plugin code is changed.

=head2 Test A Plugin From Local Dir

Test a plugin without install it.

=head2 Show %INC

Dumper %INC

=head2 Info

=head2 About

=head1 AUTHOR

Gabor Szabo

Fayland Lam  C<< <fayland at gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
