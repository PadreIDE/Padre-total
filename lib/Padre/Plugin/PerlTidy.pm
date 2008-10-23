package Padre::Plugin::PerlTidy;
use strict;
use warnings;
use Perl::Tidy;

use Wx qw(:everything);
use Wx::Event qw(:everything);

our $VERSION = '0.01';

=head1 NAME

Padre::Plugin::PerlTidy - Format perl files using Perl::Tidy

=head1 SYNOPIS

This is a simple plugin to run Perl::Tidy on your source code.

Currently there are no customisable options (since the Padre plugin system
doesn't support that yet) - however Perl::Tidy will use your normal .perltidyrc 
file if it exists (see Perl::Tidy documentation).

You'll get interesting results if you run this plugin on non-perl files..

=cut

my @menu = ( [ "Perl Tidy", \&on_run ], );

sub menu {
    my ($self) = @_;
    return @menu;
}

sub on_run {
    my ( $self, $event ) = @_;

    my $doc = $self->selected_document;
    my $src = $self->selected_document->text_get;

    do {

        # Undefine @ARGV so that Perl::Tidy doesn't try to use it
        local @ARGV;

        # Doooit
        my $output;
        eval { perltidy( source => \$src, destination => \$output ); };
        if ($@) {
            my $error_string = $@;
            Wx::MessageBox( $error_string, "PerlTidy Error", wxOK | wxCENTRE, $self );
        }
        else {
            $doc->text_set($output);
        }
    };
    return;
}

=head1 COPYRIGHT

(c) 2008 Patrick Donelan http://www.patspam.com

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=head1 WARRANTY

There is no warranty whatsoever.
If you lose data or your hair because of this program,
that's your problem.

=cut

1;
