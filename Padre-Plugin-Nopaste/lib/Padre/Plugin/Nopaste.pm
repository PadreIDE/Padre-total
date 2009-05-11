#
# This file is part of Padre::Plugin::Nopaste.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Padre::Plugin::Nopaste;

use strict;
use warnings;

use base qw{ Padre::Plugin };

our $VERSION = '0.1.0';


# -- padre plugin api, refer to Padre::Plugin

# plugin name
sub plugin_name { 'Nopaste' }

# padre interface
sub padre_interface {
    'Padre::Plugin' => 0.28,
}

# plugin menu.
sub menu_plugins_simple {
    my ($self) = @_;
    'Nopaste' => [
        "Nopaste\tCtrl+Shift+V" => 'nopaste',
    ];
}


# -- public methods

sub nopaste {
    my ($self) = @_;

    my $main     = $self->main;
    my $current  = $main->current;
    my $document = $current->document;
    my $editor   = $current->editor;
    return unless $editor;

    # no selection means autoformat current paragraph
#    if ( not $editor->GetSelectedText ) {
#        my ($b, $e) = $self->_current_paragraph;
#        return if $b == $e; # in between paragraphs
#        $editor->SetSelection($b, $e);
#    }

    require Text::Nopaste;
    my $messy  = $editor->GetSelectedText;
    my $tidied = Text::Nopaste::autoformat($messy);
    $editor->ReplaceSelection($tidied);
}


# -- private methods

#
# my ($begin, $end) = $self->_current_paragraph;
#
# return $begin and $end position of current paragraph.
#
sub _current_paragraph {
    my ($self) = @_;

    my $editor = $self->main->current->editor;
    my $curpos = $editor->GetCurrentPos;
    my $lineno = $editor->LineFromPosition($curpos);

    # check if we're in between paragraphs
    return ($curpos, $curpos) if $editor->GetLine($lineno) =~ /^\s*$/;

    # find the start of paragraph by searching backwards till we find a
    # line with only whitespace in it.
    my $para1 = $lineno;
    while ( $para1 > 0 ) {
        my $line = $editor->GetLine($para1);
        last if $line =~ /^\s*$/;
        $para1--;
    }

    # now, find the end of paragraph by searching forwards until we find
    # only white space
    my $lastline = $editor->GetLineCount;
    my $para2 = $lineno;
    while ( $para2 < $lastline ) {
        $para2++;
        my $line = $editor->GetLine($para2);
        last if $line =~ /^\s*$/;
    }

    # return the position
    my $begin = $editor->PositionFromLine($para1+1);
    my $end   = $editor->PositionFromLine($para2);
    return ($begin, $end);
}


1;
__END__

=head1 NAME

Padre::Plugin::Nopaste - send code on a nopaste website from padre



=head1 SYNOPSIS

    $ padre
    Ctrl+Shift+J



=head1 DESCRIPTION

This plugin allows one to send stuff from Padre to a nopaste website,
allowing for easy code / whatever sharing without having to open a
browser.

It is using C<App::Nopaste> underneath, so check this module's pod for
more information.


=head1 PUBLIC METHODS

=head2 Standard Padre::Plugin API

C<Padre::Plugin::Nopaste> defines a plugin which follows C<Padre::Plugin>
API. Refer to this module's documentation for more information.

The following methods are implemented:

=over 4

=item menu_plugins_simple()

=item padre_interface()

=item plugin_name()

=back


=head2 Formatting methods

=over 4

=item * nopaste()

Send the current selection to a nopaste site.

=back



=head1 BUGS

Please report any bugs or feature requests to C<padre-plugin-nopaste at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Nopaste>. I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.



=head1 SEE ALSO

Our git repository is located at L<git://repo.or.cz/padre-plugin-nopaste.git>,
and can be browsed at L<http://repo.or.cz/w/padre-plugin-nopaste.git>.


You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Nopaste>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Nopaste>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Nopaste>

=back



=head1 AUTHOR

Jerome Quelin, C<< <jquelin@cpan.org> >>



=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
