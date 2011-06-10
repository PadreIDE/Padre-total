package Wx::Scintilla;


use strict;
use warnings;
use Wx;

our $VERSION = '0.08';

# Add Wx::Scintilla distribution directory to PATH on windows so that Wx can load it
my $wx_scintilla_path;
if ( $ENV{HARNESS_ACTIVE} ) {
	$wx_scintilla_path = './blib/arch/auto/Wx/Scintilla/';
} else {
	eval { require File::ShareDir; $wx_scintilla_path = File::ShareDir::dist_dir('Wx-Scintilla'); 1; };
	if ($@) {

		# fallback
		$wx_scintilla_path = './blib/arch/auto/Wx/Scintilla/';
	}
}
$ENV{PATH} = $wx_scintilla_path . ';' . $ENV{PATH} if ( $^O eq 'MSWin32' );

# Load scintilla's DLL through Wx and ask XSLoader to load it
# NOTE: Do not use Wx::boot since it is buggy and causes test suite to fail while upgrading
Wx::load_dll('scintilla');
require XSLoader;
XSLoader::load 'Wx::Scintilla', $VERSION;

#
# properly setup inheritance tree
#

no strict;

package Wx::ScintillaTextCtrl; our $VERSION = '0.08'; @ISA = qw(Wx::Control);

package Wx::ScintillaTextEvent; our $VERSION = '0.08'; @ISA = qw(Wx::CommandEvent);

#TODO uncomment when the CPAN permission issue is resolved
#package Wx::Event;
#our $VERSION = '0.08'

use strict;

sub EVT_SCINTILLA_CHANGE($$$)            { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_CHANGE,            $_[2] ) }
sub EVT_SCINTILLA_STYLENEEDED($$$)       { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_STYLENEEDED,       $_[2] ) }
sub EVT_SCINTILLA_CHARADDED($$$)         { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_CHARADDED,         $_[2] ) }
sub EVT_SCINTILLA_SAVEPOINTREACHED($$$)  { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_SAVEPOINTREACHED,  $_[2] ) }
sub EVT_SCINTILLA_SAVEPOINTLEFT($$$)     { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_SAVEPOINTLEFT,     $_[2] ) }
sub EVT_SCINTILLA_ROMODIFYATTEMPT($$$)   { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_ROMODIFYATTEMPT,   $_[2] ) }
sub EVT_SCINTILLA_KEY($$$)               { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_KEY,               $_[2] ) }
sub EVT_SCINTILLA_DOUBLECLICK($$$)       { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DOUBLECLICK,       $_[2] ) }
sub EVT_SCINTILLA_UPDATEUI($$$)          { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_UPDATEUI,          $_[2] ) }
sub EVT_SCINTILLA_MODIFIED($$$)          { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_MODIFIED,          $_[2] ) }
sub EVT_SCINTILLA_MACRORECORD($$$)       { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_MACRORECORD,       $_[2] ) }
sub EVT_SCINTILLA_MARGINCLICK($$$)       { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_MARGINCLICK,       $_[2] ) }
sub EVT_SCINTILLA_NEEDSHOWN($$$)         { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_NEEDSHOWN,         $_[2] ) }
sub EVT_SCINTILLA_POSCHANGED($$$)        { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_POSCHANGED,        $_[2] ) }
sub EVT_SCINTILLA_PAINTED($$$)           { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_PAINTED,           $_[2] ) }
sub EVT_SCINTILLA_USERLISTSELECTION($$$) { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_USERLISTSELECTION, $_[2] ) }
sub EVT_SCINTILLA_URIDROPPED($$$)        { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_URIDROPPED,        $_[2] ) }
sub EVT_SCINTILLA_DWELLSTART($$$)        { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DWELLSTART,        $_[2] ) }
sub EVT_SCINTILLA_DWELLEND($$$)          { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DWELLEND,          $_[2] ) }
sub EVT_SCINTILLA_START_DRAG($$$)        { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_START_DRAG,        $_[2] ) }
sub EVT_SCINTILLA_DRAG_OVER($$$)         { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DRAG_OVER,         $_[2] ) }
sub EVT_SCINTILLA_DO_DROP($$$)           { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DO_DROP,           $_[2] ) }
sub EVT_SCINTILLA_ZOOM($$$)              { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_ZOOM,              $_[2] ) }
sub EVT_SCINTILLA_HOTSPOT_CLICK($$$)     { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_HOTSPOT_CLICK,     $_[2] ) }
sub EVT_SCINTILLA_HOTSPOT_DCLICK($$$)    { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_HOTSPOT_DCLICK,    $_[2] ) }
sub EVT_SCINTILLA_CALLTIP_CLICK($$$)     { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_CALLTIP_CLICK,     $_[2] ) }

1; # The end of Wx::Scintilla? :)

__END__

=pod

=head1 NAME

Wx::Scintilla - Fresh Perl wxWidgets XS bindings for Scintilla editor component

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

=head1 PLATFORMS

At the moment, Linux (Ubuntu) and Windows (Strawberry and ActivePerl) 
are supported platforms. My next goal is to support more platforms. Please
let me know if you can help out :)

On Ubuntu, you need to install the following via:

	sudo apt-get install libwxbase2.8-0 libwxgtk2.8-0 libwxbase2.8-dev libgtk2.0-dev

=head1 HISTORY

wxWidgets 2.9.1 and trunk has 2.03 so far. I searched for Perl lexer changes
in scintilla history and here is what we will be getting when we upgrade to 
2.20+

=over

=item Release 2.26

Perl folding folds "here doc"s and adds options fold.perl.at.else and
fold.perl.comment.explicit. Fold structure for Perl fixed. 

=item Release 2.20

Perl folder works for array blocks, adjacent package statements, nested PODs,
and terminates package folding at DATA, D and Z.

=item Release 1.79

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

Gabor Szabo L<http://szabgab.com> for the idea to backport Perl lexer for
wxWidgets 2.8.10 L<http://padre.perlide.org/trac/ticket/257> and all of #padre
members for the continuous support and testing. Thanks!

Robin Dunn L<http://alldunn.com/robin/> for the excellent scintilla 
contribution that he made to wxWidgets. This work is based on his codebase.
Thanks!

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wx-Scintilla>

For other issues, contact the maintainer.

=head1 AUTHOR

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=head1 SEE ALSO

wxStyledTextCtrl Documentation L<http://www.yellowbrain.com/stc/index.html>

Scintilla edit control for Win32::GUI L<Win32::GUI::Scintilla>

=head1 COPYRIGHT

Copyright 2011 Ahmad M. Zawawi.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
