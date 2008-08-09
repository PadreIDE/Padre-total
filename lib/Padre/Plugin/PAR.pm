package Padre::Plugin::PAR;
use strict;
use warnings;

use Wx        qw(:everything);
use Wx::Event qw(:everything);

our $VERSION = '0.01';

=head1 NAME

Padre::Plugin::PAR - PAR generation from Padre

=head1 SYNOPIS

This is an experimental version of the plugin using the experimental
plugin interface of Padre 0.03_02 

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
    my ($self, $event) = @_;

    #print "Stand alone called\n";
    # get name of the current file, if it is a pl file create the corresponding .exe

    my $filename = $self->get_current_filename;
    if (not $filename) {
        Wx::MessageBox( "No filename, cannot run", "Cannot create", wxOK|wxCENTRE, $self );
        return;
    }
    if (substr($filename, -3) ne '.pl') {
        Wx::MessageBox( "Currently we only support exe generation from .pl files", "Cannot create", wxOK|wxCENTRE, $self );
        return;
    }
    (my $out = $filename) =~ s/pl$/exe/;
    my $ret = system "pp $filename -o $out";
    if ($ret) {
       Wx::MessageBox( "Error generating '$out': $!", "Failed", wxOK|wxCENTRE, $self );
    } else {
       Wx::MessageBox( "$out generated", "Done", wxOK|wxCENTRE, $self );
    }

    return;
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
