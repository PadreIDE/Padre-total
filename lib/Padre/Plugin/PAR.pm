package Padre::Plugin::PAR;
use strict;
use warnings;

use Wx         qw(:everything);
use Wx::Event  qw(:everything);
use File::Temp ();

our $VERSION = '0.03';

=head1 NAME

Padre::Plugin::PAR - PAR generation from Padre

=head1 SYNOPIS

This is an experimental version of the plugin using the experimental
plugin interface of Padre 0.12_01.

After installation there should be a menu item I<Padre - PAR - Stand Alone>

Clicking on that menu item while a .pl file is in view will generate a stand alone
executable with .exe extension next to the .pl file.

If you are currently editing an unsaved buffer, it will be saved to a temporary
file for you.

=cut


my @menu = (
    ["Stand alone", \&on_stand_alone],
);

sub menu {
    my ($self) = @_;
    return @menu;
}

sub on_stand_alone {
    my ($self, $event) = @_;

    #print "Stand alone called\n";
    # get name of the current file, if it is a pl file create the corresponding .exe

    my $doc = $self->selected_document;

    my $filename = $doc->filename;
    my $tmpfh;
    my $cleanup = sub { unlink $filename if $tmpfh };
    local $SIG{INT} = $cleanup;
    local $SIG{QUIT} = $cleanup;

    if (not $filename) {
        ($filename, $tmpfh) = _to_temp_file($doc);
    }

    if ($filename !~ /\.pl$/i) {
        Wx::MessageBox( "Currently we only support exe generation from .pl files", "Cannot create", wxOK|wxCENTRE, $self );
        return;
    }
    (my $out = $filename) =~ s/pl$/exe/i;
    my $ret = system("pp", $filename, "-o", $out);
    if ($ret) {
       Wx::MessageBox( "Error generating '$out': $!", "Failed", wxOK|wxCENTRE, $self );
    } else {
       Wx::MessageBox( "$out generated", "Done", wxOK|wxCENTRE, $self );
    }

    if ($tmpfh) {
      unlink($filename);
    }

    return;
}

sub _to_temp_file {
    my $doc = shift;

    my $text = $doc->text_get();

    my ($fh, $tempfile) = File::Temp::tempfile(
      "padre_standalone_XXXXXX",
      UNLINK => 1,
      TMPDIR => File::Spec->tmpdir(),
      SUFFIX => '.pl',
    );
    local $| = 1;
    print $fh $text;
    return($tempfile, $fh);
}

1;

__END__

=head1 INSTALLATION

You can install this module like any other Perl module and it will
become available in your Padre editor. However, you can also
choose to install it into your user's Padre configuration directory only.
The necessary steps are outlined in the C<README> file in this distribution.
Essentially, you do C<perl Build.PL> and C<./Build installplugin>.

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
