package Wx::Scintilla;

use strict;
use warnings;
use Wx;
use Carp;

our $VERSION = '0.17';

# Define Perl 6 lexer
use constant wxSCINTILLA_LEX_PERL6 => 98;

# check for loaded Wx::STC
if(exists($INC{'Wx/STC.pm'})) {
	croak('Wx::Scintilla cannot be loaded alongside Wx::STC. Choose one and only one of the modules. ');
}

require XSLoader;
XSLoader::load 'Wx::Scintilla', $VERSION;

#
# properly setup inheritance tree
#

no strict;

package Wx::ScintillaTextCtrl;
our $VERSION = '0.17';
@ISA = qw(Wx::Control);

package Wx::ScintillaTextEvent;
our $VERSION = '0.17';
@ISA = qw(Wx::CommandEvent);

#Defeat the indexer by splitting the package declaration on two lines
#<<<  do not let perltidy touch this
package
    Wx::Event;
# Don't set global Wx::Event version
#>>>

use strict;

{

    # Disable Wx::EVT_STC_* event warning redefinition
    no warnings 'redefine';

    sub EVT_STC_CHANGE($$$)            { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_CHANGE,            $_[2] ) }
    sub EVT_STC_STYLENEEDED($$$)       { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_STYLENEEDED,       $_[2] ) }
    sub EVT_STC_CHARADDED($$$)         { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_CHARADDED,         $_[2] ) }
    sub EVT_STC_SAVEPOINTREACHED($$$)  { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_SAVEPOINTREACHED,  $_[2] ) }
    sub EVT_STC_SAVEPOINTLEFT($$$)     { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_SAVEPOINTLEFT,     $_[2] ) }
    sub EVT_STC_ROMODIFYATTEMPT($$$)   { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_ROMODIFYATTEMPT,   $_[2] ) }
    sub EVT_STC_KEY($$$)               { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_KEY,               $_[2] ) }
    sub EVT_STC_DOUBLECLICK($$$)       { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DOUBLECLICK,       $_[2] ) }
    sub EVT_STC_UPDATEUI($$$)          { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_UPDATEUI,          $_[2] ) }
    sub EVT_STC_MODIFIED($$$)          { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_MODIFIED,          $_[2] ) }
    sub EVT_STC_MACRORECORD($$$)       { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_MACRORECORD,       $_[2] ) }
    sub EVT_STC_MARGINCLICK($$$)       { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_MARGINCLICK,       $_[2] ) }
    sub EVT_STC_NEEDSHOWN($$$)         { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_NEEDSHOWN,         $_[2] ) }
    sub EVT_STC_POSCHANGED($$$)        { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_POSCHANGED,        $_[2] ) }
    sub EVT_STC_PAINTED($$$)           { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_PAINTED,           $_[2] ) }
    sub EVT_STC_USERLISTSELECTION($$$) { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_USERLISTSELECTION, $_[2] ) }
    sub EVT_STC_URIDROPPED($$$)        { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_URIDROPPED,        $_[2] ) }
    sub EVT_STC_DWELLSTART($$$)        { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DWELLSTART,        $_[2] ) }
    sub EVT_STC_DWELLEND($$$)          { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DWELLEND,          $_[2] ) }
    sub EVT_STC_START_DRAG($$$)        { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_START_DRAG,        $_[2] ) }
    sub EVT_STC_DRAG_OVER($$$)         { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DRAG_OVER,         $_[2] ) }
    sub EVT_STC_DO_DROP($$$)           { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DO_DROP,           $_[2] ) }
    sub EVT_STC_ZOOM($$$)              { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_ZOOM,              $_[2] ) }
    sub EVT_STC_HOTSPOT_CLICK($$$)     { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_HOTSPOT_CLICK,     $_[2] ) }
    sub EVT_STC_HOTSPOT_DCLICK($$$)    { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_HOTSPOT_DCLICK,    $_[2] ) }
    sub EVT_STC_CALLTIP_CLICK($$$)     { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_CALLTIP_CLICK,     $_[2] ) }
}

1; # The end of Wx::Scintilla? :)

__END__

=pod

=head1 NAME

Wx::Scintilla - wxWidgets Perl XS wrapper for the Scintilla editor component

=head1 SYNOPSIS

    #----> My first scintilla Wx editor :)
    package My::Scintilla::Editor;

    use strict;
    use warnings;

    # Load Wx::Scintilla
    use Wx::Scintilla ();    # replaces use Wx::STC
    use base 'Wx::ScintillaTextCtrl';    # replaces Wx::StyledTextCtrl

    use Wx qw(:everything);
    use Wx::Event;

    # Override the constructor to Enable Perl support in the editor
    sub new {
        my ( $class, $parent ) = @_;
        my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ 750, 700 ] );

        # Set the font
        my $font = Wx::Font->new( 10, wxTELETYPE, wxNORMAL, wxNORMAL );
        $self->SetFont($font);
        $self->StyleSetFont( wxSTC_STYLE_DEFAULT, $font );
        $self->StyleClearAll();

        # Set the various Perl lexer colors
        $self->StyleSetForeground( 0,  Wx::Colour->new( 0x00, 0x00, 0x7f ) );
        $self->StyleSetForeground( 1,  Wx::Colour->new( 0xff, 0x00, 0x00 ) );
        $self->StyleSetForeground( 2,  Wx::Colour->new( 0x00, 0x7f, 0x00 ) );
        $self->StyleSetForeground( 3,  Wx::Colour->new( 0x7f, 0x7f, 0x7f ) );
        $self->StyleSetForeground( 4,  Wx::Colour->new( 0x00, 0x7f, 0x7f ) );
        $self->StyleSetForeground( 5,  Wx::Colour->new( 0x00, 0x00, 0x7f ) );
        $self->StyleSetForeground( 6,  Wx::Colour->new( 0xff, 0x7f, 0x00 ) );
        $self->StyleSetForeground( 7,  Wx::Colour->new( 0x7f, 0x00, 0x7f ) );
        $self->StyleSetForeground( 8,  Wx::Colour->new( 0x00, 0x00, 0x00 ) );
        $self->StyleSetForeground( 9,  Wx::Colour->new( 0x7f, 0x7f, 0x7f ) );
        $self->StyleSetForeground( 10, Wx::Colour->new( 0x00, 0x00, 0x7f ) );
        $self->StyleSetForeground( 11, Wx::Colour->new( 0x00, 0x00, 0xff ) );
        $self->StyleSetForeground( 12, Wx::Colour->new( 0x7f, 0x00, 0x7f ) );
        $self->StyleSetForeground( 13, Wx::Colour->new( 0x40, 0x80, 0xff ) );
        $self->StyleSetForeground( 17, Wx::Colour->new( 0xff, 0x00, 0x7f ) );
        $self->StyleSetForeground( 18, Wx::Colour->new( 0x7f, 0x7f, 0x00 ) );
        $self->StyleSetBold( 12, 1 );
        $self->StyleSetSpec( wxSTC_H_TAG, "fore:#0000ff" );

        # set the lexer to Perl 5
        $self->SetLexer(wxSTC_LEX_PERL);

        return $self;
    }

    #----> DEMO EDITOR APPLICATION

    # First, define an application object class to encapsulate the application itself
    package DemoEditorApp;

    use strict;
    use warnings;
    use Wx;
    use base 'Wx::App';

    # We must override OnInit to build the window
    sub OnInit {
        my $self = shift;

        my $frame = Wx::Frame->new(
        undef,                           # no parent window
        -1,                              # no window id
        'My First Scintilla Editor!',    # Window title
        );

        my $editor = My::Scintilla::Editor->new(
        $frame,                          # Parent window
        );

        $frame->Show(1);
        return 1;
    }

    # Create the application object, and pass control to it.
    package main;
    my $app = DemoEditorApp->new;
    $app->MainLoop;


=head1 DESCRIPTION

While we already have a good scintilla editor component support via 
Wx::StyledTextCtrl in Perl, we already suffer from an older scintilla package 
and thus lagging Perl support in the popular Wx Scintilla component. wxWidgets 
L<http://wxwidgets.org> has a *very slow* release timeline. Scintilla is a 
contributed project which means it will not be the latest by the time a new 
wxWidgets distribution is released. And on the scintilla front, the Perl 5 lexer 
is not 100% bug free even and we do not have any kind of Perl 6 support in 
Scintilla.

The ambitious goal of this project is to provide fresh Perl 5 and maybe 6 
support in L<Wx> while preserving compatibility with Wx::StyledTextCtrl
and continually contribute it back to Scintilla project.

Note: You cannot load Wx::STC and Wx::Scintilla in the same application. They
are mutually exclusive. The wxSTC_... events are handled by one library or
the other.

=head1 MANUAL

If you are looking for more API documentation, please consult L<Wx::Scintilla::Manual>

=head1 PLATFORMS

At the moment, Linux (Debian, Ubuntu, Fedora, CentOS) and Windows (Strawberry
and ActivePerl)  are supported platforms. My next goal is to support more 
platforms. Please let me know if you can help out :)

On Debian/Ubuntu, you need to install the following via:

    sudo apt-get install libgtk2.0-dev

On MacOS 64-bit by default you need to install a 32-bit Perl in order to
install wxWidgets 2.8.x. Please refer to 
L<http://wiki.wxperl.info/w/index.php/Mac_OS_X_Platform_Notes> for more information.

=head1 HISTORY

wxWidgets 2.9.1 and development have Scintilla 2.03 so far. I searched for Perl lexer
changes in scintilla history and here is what we will be getting when we upgrade to
2.20+.

=over

=item Release 2.26

Perl folding folds "here doc"s and adds options fold.perl.at.else and
fold.perl.comment.explicit. Fold structure for Perl fixed. 

=item Release 2.20

Perl folder works for array blocks, adjacent package statements, nested PODs,
and terminates package folding at DATA, D and Z.

=item Release 1.79 (Currently we're here)

Perl lexer bug fixed where previous lexical states persisted causing "/" special 
case styling and subroutine prototype styling to not be correct.

=item Release 1.78

Perl lexer fixes problem with string matching caused by line endings.

=item Release 1.77

Perl lexer update.

=item Release 1.76

Perl lexer handles defined-or operator "".

=item Release 1.75

Perl lexer enhanced for handling minus-prefixed barewords, underscores in
numeric literals and vector/version strings, D and Z similar to END, subroutine 
prototypes as a new lexical class, formats and format blocks as new lexical
classes, and '/' suffixed keywords and barewords.

=item Release 1.71

Perl lexer allows UTF-8 identifiers and has some other small improvements.

=back

=head1 ACKNOWLEDGEMENTS

Neil Hudgson for creating and maintaining the excellent Scintilla project
L<http://scintilla.org>. Thanks!

Robin Dunn L<http://alldunn.com/robin/> for the excellent scintilla 
contribution that he made to wxWidgets. This work is based on his codebase.
Thanks!

Mark dootson L<http://search.cpan.org/~mdootson/> for his big effort to make
Wx::Scintilla compilable on various platforms. Big thanks!

Heiko Jansen and Gabor Szabo L<http://szabgab.com> for the idea to backport
Perl lexer for wxWidgets 2.8.10 L<http://padre.perlide.org/trac/ticket/257>
and all of #padre members for the continuous support and testing. Thanks!

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wx-Scintilla>

For other issues, contact the maintainer.

=head1 AUTHOR

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

Mark Dootson <http://www.wxperl.co.uk>

=head1 SEE ALSO

Wx::Scintilla Manual L<Wx::Scintilla::Manual>

wxStyledTextCtrl Documentation L<http://www.yellowbrain.com/stc/index.html>

Scintilla edit control for Win32::GUI L<Win32::GUI::Scintilla>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Ahmad M. Zawawi.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

License for Scintilla

Included Scintilla source is copyrighted 1998-2011 by Neil Hodgson <neilh@scintilla.org>

Permission to use, copy, modify, and distribute this software and its documentation for any purpose and without fee is hereby granted, provided that the above copyright notice appear in all copies and that both that copyright notice and this permission notice appear in supporting documentation.

NEIL HODGSON DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL NEIL HODGSON BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

=cut
