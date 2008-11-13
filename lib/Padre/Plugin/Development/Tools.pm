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

# TODO fix this
# we need to create anonymous subs in order to makes
# sure reloading the module changes the call as well
# A better to replace the whole Plugins/ menu when we
# reload plugins.
my @menu = (
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
