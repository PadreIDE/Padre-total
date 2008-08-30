package Padre::Plugin::PAR;
use strict;
use warnings;

use Wx         qw(:everything);
use Wx::Event  qw(:everything);
use File::Temp ();

our $VERSION = '0.02';

=head1 NAME

Padre::Plugin::PAR - PAR generation from Padre

=head1 SYNOPIS

This is an experimental version of the plugin using the experimental
plugin interface of Padre 0.06

After installation there should be a menu item Padre - PAR - Stand Alone

Clicking on that menu item while a .pl file is in view will generate a stand alone
executable with .exe extension next to the .pl file.

=cut


my @menu = (
    ["Stand alone", \&on_stand_alone],
);

sub menu {
    my ($self) = @_;
    return @menu;
}

sub on_stand_alone {
    my ($mw, $event) = @_;

    #print "Stand alone called\n";
    # get name of the current file, if it is a pl file create the corresponding .exe

    my $filename = $mw->get_current_filename;
    my $tmpfh;
    my $cleanup = sub { unlink $filename if $tmpfh };
    local $SIG{INT} = $cleanup;
    local $SIG{QUIT} = $cleanup;

    if (not $filename) {
        ($filename, $tmpfh) = _to_temp_file($mw);
    }

    if ($filename !~ /\.pl$/i) {
        Wx::MessageBox( "Currently we only support exe generation from .pl files", "Cannot create", wxOK|wxCENTRE, $mw );
        return;
    }
    (my $out = $filename) =~ s/pl$/exe/i;
    my $ret = system("pp", $filename, "-o", $out);
    if ($ret) {
       Wx::MessageBox( "Error generating '$out': $!", "Failed", wxOK|wxCENTRE, $mw );
    } else {
       Wx::MessageBox( "$out generated", "Done", wxOK|wxCENTRE, $mw );
    }

    if ($tmpfh) {
      unlink($filename);
    }

    return;
}

sub _to_temp_file {
    my $mw = shift;

    my $id   = $mw->{notebook}->GetSelection;
    my $page = $mw->{notebook}->GetPage($id);
    my $code = $page->GetTextRange(0, $page->GetLength());
 
    my ($fh, $tempfile) = File::Temp::tempfile(
      "padre_standalone_XXXXXX",
      UNLINK => 1,
      TMPDIR => File::Spec->tmpdir(),
      SUFFIX => '.pl',
    );
    local $| = 1;
    warn $code;
    print $fh $code;
    return($tempfile, $fh);
}

=head1 COPYRIGHT

(c) 2008 Gabor Szabo http://www.szabgab.com/

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=head1 WARRANTY

There is no warranty whatsoever.
If you lose data or your hair because of this program,
that's your problem.

=cut

1;
