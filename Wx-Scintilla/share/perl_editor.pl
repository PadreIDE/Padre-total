#----> Perl Wx::Scintilla editor :)
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
	$self->StyleSetForeground( Wx::wxSTC_PL_DEFAULT,
		Wx::Colour->new( 0x00, 0x00, 0x7f ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_ERROR,
		Wx::Colour->new( 0xff, 0x00, 0x00 ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_COMMENTLINE,
		Wx::Colour->new( 0x00, 0x7f, 0x00 ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_POD,
		Wx::Colour->new( 0x7f, 0x7f, 0x7f ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_NUMBER,
		Wx::Colour->new( 0x00, 0x7f, 0x7f ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_WORD,
		Wx::Colour->new( 0x00, 0x00, 0x7f ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_STRING,
		Wx::Colour->new( 0xff, 0x7f, 0x00 ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_CHARACTER,
		Wx::Colour->new( 0x7f, 0x00, 0x7f ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_PUNCTUATION,
		Wx::Colour->new( 0x00, 0x00, 0x00 ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_PREPROCESSOR,
		Wx::Colour->new( 0x7f, 0x7f, 0x7f ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_OPERATOR,
		Wx::Colour->new( 0x00, 0x00, 0x7f ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_IDENTIFIER,
		Wx::Colour->new( 0x00, 0x00, 0xff ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_SCALAR,
		Wx::Colour->new( 0x7f, 0x00, 0x7f ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_ARRAY,
		Wx::Colour->new( 0x40, 0x80, 0xff ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_HASH,
		Wx::Colour->new( 0xff, 0x00, 0x7f ) );
	$self->StyleSetForeground( Wx::wxSTC_PL_SYMBOLTABLE,
		Wx::Colour->new( 0x7f, 0x7f, 0x00 ) );

	use constant {
		# Must be defined by Wx::Scintilla
		wxSTC_PL_STRING_VAR    => 43,
		wxSTC_PL_XLAT          => 44,
		wxSTC_PL_REGEX_VAR     => 54,
		wxSTC_PL_REGSUBST_VAR  => 55,
		wxSTC_PL_BACKTICKS_VAR => 57,
		wxSTC_PL_HERE_QQ_VAR   => 61,
		wxSTC_PL_HERE_QX_VAR   => 62,
		wxSTC_PL_STRING_QQ_VAR => 64,
		wxSTC_PL_STRING_QX_VAR => 65,
		wxSTC_PL_STRING_QR_VAR => 66,

		wxSTC_ANNOTATION_BOXED => 2,
	};

	my $color1 = Wx::Colour->new( 0xff, 0x7f, 0x00 );
	my $color2 = Wx::Colour->new( 0x00, 0x00, 0xff );
	my %styles = (
		Wx::wxSTC_PL_REGEX         => $color1,
		Wx::wxSTC_PL_REGSUBST      => $color1,
		Wx::wxSTC_PL_LONGQUOTE     => $color1,
		Wx::wxSTC_PL_BACKTICKS     => $color1,
		Wx::wxSTC_PL_DATASECTION   => $color1,
		Wx::wxSTC_PL_HERE_DELIM    => $color1,
		Wx::wxSTC_PL_HERE_Q        => $color1,
		Wx::wxSTC_PL_HERE_QQ       => $color1,
		Wx::wxSTC_PL_HERE_QX       => $color1,
		Wx::wxSTC_PL_STRING_Q      => $color1,
		Wx::wxSTC_PL_STRING_QQ     => $color1,
		Wx::wxSTC_PL_STRING_QX     => $color1,
		Wx::wxSTC_PL_STRING_QR     => $color1,
		Wx::wxSTC_PL_STRING_QW     => $color1,
		Wx::wxSTC_PL_POD_VERB      => $color1,
		Wx::wxSTC_PL_SUB_PROTOTYPE => $color1,
		Wx::wxSTC_PL_FORMAT_IDENT  => $color1,
		Wx::wxSTC_PL_FORMAT        => $color1,
		Wx::wxSTC_PL_STRING_QQ     => $color1,
		Wx::wxSTC_PL_STRING_QX     => $color1,
		Wx::wxSTC_PL_STRING_QR     => $color1,
		Wx::wxSTC_PL_STRING_QW     => $color1,
		Wx::wxSTC_PL_POD_VERB      => $color1,
		Wx::wxSTC_PL_SUB_PROTOTYPE => $color1,
		Wx::wxSTC_PL_FORMAT_IDENT  => $color1,
		Wx::wxSTC_PL_FORMAT        => $color1,

		wxSTC_PL_STRING_VAR()    => $color2,
		wxSTC_PL_REGEX_VAR()     => $color2,
		wxSTC_PL_REGSUBST_VAR()  => $color2,
		wxSTC_PL_BACKTICKS_VAR() => $color2,
		wxSTC_PL_HERE_QQ_VAR()   => $color2,
		wxSTC_PL_HERE_QX_VAR()   => $color2,
		wxSTC_PL_STRING_QQ_VAR() => $color2,
		wxSTC_PL_STRING_QX_VAR() => $color2,
		wxSTC_PL_STRING_QR_VAR() => $color2,
	);

	for my $style ( keys %styles ) {
		$self->StyleSetForeground( $style, $styles{$style} );
	}

	$self->StyleSetBold( Wx::wxSTC_PL_WORD, 1 );
	$self->StyleSetSpec( wxSTC_H_TAG, "fore:#0000ff" );

	# set the lexer to Perl 5
	$self->SetLexer(wxSTC_LEX_PERL);
	$self->SetStyleBits($self->GetStyleBitsNeeded);

	my @keywords = qw(
	  NULL __FILE__ __LINE__ __PACKAGE__ __DATA__ __END__ AUTOLOAD
	  BEGIN CORE DESTROY END EQ GE GT INIT LE LT NE CHECK abs accept
	  alarm and atan2 bind binmode bless caller chdir chmod chomp chop
	  chown chr chroot close closedir cmp connect continue cos crypt
	  dbmclose dbmopen defined delete die do dump each else elsif endgrent
	  endhostent endnetent endprotoent endpwent endservent eof eq eval
	  exec exists exit exp fcntl fileno flock for foreach fork format
	  formline ge getc getgrent getgrgid getgrnam gethostbyaddr gethostbyname
	  gethostent getlogin getnetbyaddr getnetbyname getnetent getpeername
	  getpgrp getppid getpriority getprotobyname getprotobynumber getprotoent
	  getpwent getpwnam getpwuid getservbyname getservbyport getservent
	  getsockname getsockopt glob gmtime goto grep gt hex if index
	  int ioctl join keys kill last lc lcfirst le length link listen
	  local localtime lock log lstat lt map mkdir msgctl msgget msgrcv
	  msgsnd my ne next no not oct open opendir or ord our pack package
	  pipe pop pos print printf prototype push quotemeta qu
	  rand read readdir readline readlink readpipe recv redo
	  ref rename require reset return reverse rewinddir rindex rmdir
	  scalar seek seekdir select semctl semget semop send setgrent
	  sethostent setnetent setpgrp setpriority setprotoent setpwent
	  setservent setsockopt shift shmctl shmget shmread shmwrite shutdown
	  sin sleep socket socketpair sort splice split sprintf sqrt srand
	  stat study sub substr symlink syscall sysopen sysread sysseek
	  system syswrite tell telldir tie tied time times truncate
	  uc ucfirst umask undef unless unlink unpack unshift untie until
	  use utime values vec wait waitpid wantarray warn while write
	  xor given when default say state UNITCHECK
	);
	$self->SetKeyWords( 0, join( ' ', @keywords ) );

	my $filename = 'share/perl-test-interpolation.pl.txt';
	if ( open my $fh, "<", $filename ) {
		local $/ = undef;
		my $content = <$fh>;
		$self->SetText($content);
	}
	else {
		die "Cannot open $filename for reading\n";
	}
	$self->SetFocus;

	Wx::Event::EVT_STC_INDICATOR_CLICK( $self, $self, sub {
		print "EVT_STC_INDICATOR_CLICK triggered\n";
	} );

	Wx::Event::EVT_STC_INDICATOR_RELEASE( $self, $self, sub {
		print "EVT_STC_INDICATOR_RELEASE triggered\n";
	} );

	$self->AnnotationClearAll;
	$self->AnnotationSetText(2, "1st line\nSecond line");
	$self->AnnotationSetStyles(2, ['fore:#FFFFFF,back:#FF0000','fore:#FFFFFF,back:#FF0000']);

	#TODO must be in Wx namespace
	$self->AnnotationSetVisible( wxSTC_ANNOTATION_BOXED );

	$self->IndicatorSetForeground( 0, Wx::Colour->new("red") );
	$self->SetIndicatorCurrent(0);
	$self->IndicatorFillRange(0, 20);

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
		'Perl Wx::Scintilla editor!',    # Window title
		[ -1,  -1 ],
		[ 750, 700 ],
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
