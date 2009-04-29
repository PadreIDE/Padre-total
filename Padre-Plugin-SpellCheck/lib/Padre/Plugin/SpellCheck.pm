#
# This file is part of Padre::Plugin::SpellCheck.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Padre::Plugin::SpellCheck;

use warnings;
use strict;

use File::Basename        qw{ fileparse };
use File::Spec::Functions qw{ catfile };
use Module::Util          qw{ find_installed };

our $VERSION = '1.0.0';

use base 'Padre::Plugin';
use Padre::Current;
use Padre::Plugin::SpellCheck::Dialog;
use Padre::Plugin::SpellCheck::Engine;


# -- padre plugin api, refer to Padre::Plugin

# plugin name
sub plugin_name { 'Spell checking' }

# plugin icon
sub plugin_icon {
    # find resource path
    my $pkgpath = find_installed(__PACKAGE__);
    my (undef, $dirname, undef) = fileparse($pkgpath);
    my $iconpath = catfile( $dirname,
        'SpellCheck', 'share', 'icons', 'spellcheck.png');

    # create and return icon
    return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );
}

# padre interfaces
sub padre_interfaces {
    'Padre::Plugin' => '0.26',
}

# plugin menu.
sub menu_plugins_simple {
    'Spell Check' => [
        "Check spelling\tF7" => 'spell_check',
    ];
}


# -- public methods

sub spell_check {
    my ( $self ) = shift;

    my $main   = Padre::Current->main;
    my $engine = Padre::Plugin::SpellCheck::Engine->new;

    # fetch text to check
    my $selection = Padre::Current->text;
    my $wholetext = Padre::Current->document->text_get;
    my $text   = $selection || $wholetext;
    my $offset = $selection ? Padre::Current->editor->GetSelectionStart : 0;

    # try to find a mistake
    my ($word, $pos) = $engine->check( $text );

    # no mistake means we're done
    if ( not defined $word ) {
        $main->message( Wx::gettext( 'Spell check finished.' ), 'Padre' );
        return;
    }

    my $dialog = Padre::Plugin::SpellCheck::Dialog->new(
        text   => $text,
        error  => [ $word, $pos ],
        engine => $engine,
        offset => $offset,
    );
    $dialog->Show;
}

1;
__END__

=head1 NAME

Padre::Plugin::SpellCheck - check spelling in Padre



=head1 SYNOPSIS

    $ padre file-with-spell-errors
    F7



=head1 DESCRIPTION

This plugins allows one to checking her text spelling within Padre using
C<F7> (standard spelling shortcut accross text processors). It is using
C<Text::Aspell> underneath, so check this module's pod for more
information.

Of course, you need to have the aspell binary and dictionnary installed.



=head1 PUBLIC METHODS

=head2 Standard Padre::Plugin API

C<Padre::Plugin::SpellCheck> defines a plugin which follows
C<Padre::Plugin> API. Refer to this module's documentation for more
information.

The following methods are implemented:

=over 4

=item menu_plugins_simple()

=item padre_interfaces()

=item plugin_icon()

=item plugin_name()

=back


=head2 Spell checking methods

=over 4

=item * spell_check()

Spell checks the current selection (or the whole document).

=back



=head1 BUGS

Please report any bugs or feature requests to C<padre-plugin-spellcheck
at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-
SpellCheck>. I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.



=head1 SEE ALSO

Plugin icon courtesy of Mark James, at
L<http://www.famfamfam.com/lab/icons/silk/>.

Our svn repository is located at L<http://svn.perlide.org/padre/trunk/Padre-Plugin-
SpellCheck>, and can be browsed at L<http://padre.perlide.org/browser/trunk/Padre-Plugin-
SpellCheck>.


You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-SpellCheck>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-SpellCheck>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-SpellCheck>

=back


Everything aspell related: L<http://aspell.net>.



=head1 AUTHOR

Jerome Quelin, C<< <jquelin@cpan.org> >>

Original version from Fayland Lam, C<< <fayland at gmail.com> >>



=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Fayland Lam, all rights reserved.

Copyright (c) 2009 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
