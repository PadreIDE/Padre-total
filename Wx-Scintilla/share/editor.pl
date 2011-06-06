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
