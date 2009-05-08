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
use File::Spec::Functions qw{ catdir catfile };
use Module::Util          qw{ find_installed };

our $VERSION = '1.1.1';

use base 'Padre::Plugin';
use Padre::Current;
use Padre::Plugin::SpellCheck::Dialog;
use Padre::Plugin::SpellCheck::Engine;
use Padre::Plugin::SpellCheck::Preferences;


# -- padre plugin api, refer to Padre::Plugin

# plugin name
sub plugin_name { Wx::gettext('Spell check') }

# plugin icon
sub plugin_icon {
    # find resource path
    my $pkgpath = find_installed(__PACKAGE__);
    my (undef, $dirname, undef) = fileparse($pkgpath);
    my $iconpath = catfile( _sharedir(), 'icons', 'spellcheck.png');

    # create and return icon
    return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );
}

# directory where to find the translations
sub plugin_locale_directory {
    return catdir( _sharedir(), 'locale' );
}

# padre interfaces
sub padre_interfaces {
    'Padre::Plugin' => '0.26',
}

# plugin menu.
sub menu_plugins_simple {
    Wx::gettext('Spell check') => [
        Wx::gettext("Check spelling\tF7") => 'spell_check',
        Wx::gettext("Preferences")        => 'spell_preferences',
    ];
}


# -- public methods

sub config {
    my ($self) = @_;
    my $config = {
        dictionary => 'en_US',
    };
    return $self->config_read || $config;
}

sub spell_check {
    my ($self) = @_;
    my $main   = Padre::Current->main;

    # TODO: maybe grey out the menu option if
    # no file is opened?
    unless ($main->current->document) {
        $main->message( Wx::gettext( 'No document opened.' ), 'Padre' );
	    return;
    }
    
    my $engine = Padre::Plugin::SpellCheck::Engine->new($self);

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
        plugin => $self,
    );
    $dialog->ShowModal;
}

sub spell_preferences {
    my ($self) = @_;
    my $prefs  = Padre::Plugin::SpellCheck::Preferences->new($self);
    $prefs->Show;
}


# -- private methods

#
# my $dir = $self->_sharedir;
#
# return the private share directory where the module resources are stored.
#
sub _sharedir {
    # find resource path
    my $pkgpath = find_installed(__PACKAGE__);
    my (undef, $dirname, undef) = fileparse($pkgpath);
    return catdir( $dirname, 'SpellCheck', 'share' );
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
C<F7> (standard spelling shortcut accross text processors). One can change
the dictionary language used in the preferences window (menu Plugins /
SpellCheck / Preferences).

This plugin is using C<Text::Aspell> underneath, so check this module's
pod for more information.

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

=item plugin_locale_directory()

=item plugin_name()

=back


=head2 Spell checking methods

=over 4

=item * config()

Return the plugin's configuration, or a suitable default one if none
exist previously.

=item * spell_check()

Spell checks the current selection (or the whole document).

=item * spell_preferences()

Open the check spelling preferences window.

=back



=head1 BUGS

Spell-checking non-ascii files has bugs: the selection does not
match the word boundaries, and as the spell checks moves further in
the document, offsets are totally irrelevant. This is a bug in
C<Wx::StyledTextCtrl> that has some unicode problems... So
unfortunately, there's nothing that I can do in this plugin to
tackle this bug.

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
