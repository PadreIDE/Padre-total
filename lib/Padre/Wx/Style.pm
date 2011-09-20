package Padre::Wx::Style;

use 5.008;
use strict;
use warnings;
use IO::File             ();
use Params::Util         ();
use Padre::Constant      ();
use Padre::Util          ();
use Padre::Wx            ();
use Padre::Locale        ();
use Padre::Config::Style ();

our $VERSION = '0.91';

# Locate the directories containing styles
use constant {
	CORE_DIRECTORY => Padre::Util::sharedir('styles'),
	USER_DIRECTORY => File::Spec->catdir(
		Padre::Constant::CONFIG_DIR,
		'styles',
	),
};





######################################################################
# Configuration

# Commands allowed in the style
my %PARAM = (
	name                    => [ 2, 'name' ],
	style                   => [ 1, 'mime' ],
	include                 => [ 1, 'mime' ],
	SetForegroundColour     => [ 1, 'color' ],
	SetBackgroundColour     => [ 1, 'color' ],
	SetCaretLineBackground  => [ 1, 'color' ],
	SetCaretForeground      => [ 1, 'color' ],
	SetWhitespaceBackground => [ 1, 'color' ],
	SetWhitespaceForeground => [ 1, 'color' ],
	SetSelBackground        => [ 2, 'style,color' ],
	SetSelForeground        => [ 1, 'style,color' ],
	StyleSetBackground      => [ 2, 'style,color' ],
	StyleSetForeground      => [ 2, 'style,color' ],
	StyleSetBold            => [ 2, 'style,boolean' ],
	StyleSetItalic          => [ 2, 'style,boolean' ],
	StyleSetEOLFilled       => [ 2, 'style,boolean' ],
	StyleSetUnderline       => [ 2, 'style,boolean' ],
	StyleSetSpec            => [ 2, 'style,spec' ],
);

# Fallback path of next best styles if no style exists.
# The fallback of last resort is automatically to text/plain
my %FALLBACK = (
	'application/x-psgi'     => 'application/x-perl',
	'application/x-php'      => 'application/perl', # Temporary solution
	'application/json'       => 'application/javascript',
	'application/javascript' => 'text/x-c',
	'text/x-java-source'     => 'text/x-c',
	'text/x-c++src'          => 'text/x-c',
	'text/x-csharp'          => 'text/x-c',
);





######################################################################
# Style Repository

sub files {
	my $class  = shift;
	my %styles = ();

	# Scan style directories
	foreach my $directory ( USER_DIRECTORY, CORE_DIRECTORY ) {
		next unless -d $directory;

		# Search the directory
		local *STYLEDIR;
		unless ( opendir( STYLEDIR, $directory ) ) {
			die "Failed to read '$directory'";
		}
		foreach my $file ( readdir STYLEDIR ) {
			next unless $file =~ s/\.txt\z//;
			next unless Params::Util::_IDENTIFIER($file);
			next if $styles{$file};
			$styles{$file} = File::Spec->catfile(
				$directory,
				"$file.txt"
			);
		}
		closedir STYLEDIR;
	}

	return \%styles;
}

# Get the file name for a named style
sub file {
	my $class = shift;
	my $name  = shift;
	foreach my $directory ( USER_DIRECTORY, CORE_DIRECTORY ) {
		my $file = File::Spec->catfile(
			$directory,
			"$name.txt",
		);
		return $file if -f $file;
	}
	return undef;
}

sub label {
	my $class = shift;
	my $name  = shift;
	my $file  = $class->file($name);
	unless ( $file ) {
		die "The style '$name' does not exist";
	}

	# Open the file
	my $line   = 0;
	my %names  = ();
	my $handle = IO::File->new( $file, 'r' ) or return;
	while ( defined( my $string = <$handle> ) ) {
		$line++;

		# Clean the line
		$string =~ s/^\s*//s;
		$string =~ s/\s*\z//s;

		# Skip blanks and comments
		next unless $string =~ /^\s*[^#]/;

		# Split the line into a command and params
		my @list = split /\s+/, $string;
		my $cmd  = shift @list;

		# We only care about name
		next unless defined $cmd;
		next unless $cmd eq 'name';
		next unless @list >= 2;

		# Does the language exist
		my $lang = shift @list;
		unless ( Padre::Locale::rfc4646_exists($lang) ) {
			die "Line $line: Unknown language in command '$string'";
		}

		# Save the name
		$names{$lang} = join ' ', @list;
	}
	$handle->close;
}

sub find {
	my $class = shift;
	my $name  = shift;
	my $file  = $class->file($name);
	unless ( $file ) {
		die "The style '$name' does not exist";
	}
	return $class->load($file);
}





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self = bless { @_, code => {} }, $class;
	unless ( defined $self->name ) {
		die "No default en-gb name for style";
	}
	unless ( defined $self->mime ) {
		die "No default text/plain style";
	}

	return $self;
}

sub load {
	my $class = shift;
	my $file  = shift;
	unless ( -f $file ) {
		die "Missing or invalid style file '$file'";
	}

	# Open the file
	my $handle = IO::File->new( $file, 'r' ) or return;
	my $self   = $class->parse($handle);
	$handle->close;

	return $self;
}

sub name {
	my $self = shift;
	my $lang = shift || 'en-gb';
	return $self->{name}->{$lang};
}

sub mime {
	my $self = shift;
	my $mime = shift || 'text/plain';
	while ( not $self->{mime}->{$mime} ) {
		if ( $mime eq 'text/plain' ) {

			# A null seqeunce... I guess...
			return [];
		} else {
			$mime = $FALLBACK{$mime} || 'text/plain';
		}
	}
	return $self->{mime}->{$mime};
}





######################################################################
# Style Parser

sub parse {
	my $class = shift;
	my $handle = Params::Util::_HANDLE(shift) or die "Not a file handle";

	# Parse the file
	my %name   = ();
	my %styles = ();
	my $style  = undef;
	my $line   = 0;
	while ( defined( my $string = <$handle> ) ) {
		$line++;

		# Clean the line
		$string =~ s/^\s*//s;
		$string =~ s/\s*\z//s;

		# Skip blanks and comments
		next unless $string =~ /^\s*[^#]/;

		# Split the line into a command and params
		my @list = split /\s+/, $string;
		my $cmd = shift @list;
		unless ( defined $PARAM{$cmd} ) {
			die "Line $line: Unsupported style command '$string'";
		}
		unless ( @list >= $PARAM{$cmd}->[0] ) {
			die "Line $line: Insufficient parameters in command '$string'";
		}

		# Handle special commands
		if ( $cmd eq 'name' ) {

			# Does the language exist
			my $lang = shift @list;
			unless ( Padre::Locale::rfc4646_exists($lang) ) {
				die "Line $line: Unknown language in command '$string'";
			}

			# Save the name
			$name{$lang} = join ' ', @list;

		} elsif ( $cmd eq 'style' ) {

			# Switch to the new mime type
			$style = ( $styles{ $list[0] } ||= [] );

		} elsif ( $cmd eq 'include' ) {

			# Copy another style as a starting point
			my $copy = $styles{ $list[0] };
			unless ($copy) {
				die "Line $line: Style '$list[0]' is not defined (yet)";
			}
			push @$style, @$copy;

		} elsif ( $PARAM{$cmd}->[1] eq 'color' ) {

			# General commands that are passed a single colour
			my $color = $class->parse_color( $line, shift @list );
			push @$style, $cmd, [$color];

		} elsif ( $PARAM{$cmd}->[1] eq 'style,color' ) {

			# Style specific commands that are passed a single color
			my $id = $class->parse_style( $line, shift @list );
			my $color = $class->parse_color( $line, shift @list );
			push @$style, $cmd, [ $id, $color ];

		} elsif ( $PARAM{$cmd}->[1] eq 'style,boolean' ) {

			# Style specific commands that are passed a boolean value
			my $id = $class->parse_style( $line, shift @list );
			my $boolean = $class->parse_boolean( $line, shift @list );
			push @$style, $cmd, [ $id, $boolean ];

		} elsif ( $PARAM{$cmd}->[1] eq 'style,spec' ) {

			# Style command that is passed a spec string
			my $style = $class->parse_style( $line, shift @list );
			my $spec = shift @list;
		} else {
			die "Line $line: Unsupported style command '$string'";
		}
	}

	return $class->new(
		name => \%name,
		mime => \%styles,
	);
}

sub parse_color {
	my $class  = shift;
	my $line   = shift;
	my $string = shift;
	return Padre::Wx::color($string);
}

sub parse_style {
	my $class  = shift;
	my $line   = shift;
	my $string = shift;
	my $copy   = $string;
	if ( defined Params::Util::_NONNEGINT($string) ) {
		return $string;
	} elsif ( $string =~ /^PADRE_\w+\z/ ) {
		unless ( Padre::Constant->can($string) ) {
			die "Line $line: Unknown or unsupported style '$copy'";
		}
		$string = "Padre::Constant::$string";
	} elsif ( $string =~ /^wxSTC_\w+\z/ ) {
		unless ( Wx::->can($string) ) {
			die "Line $line: Unknown or unsupported style '$copy'";
		}
		$string = "Wx::$string";
	} else {
		die "Line $line: Unknown or unsupported style '$copy'";
	}

	# Capture the numeric form of the constant
	no strict 'refs';
	$string = eval { $string->() };
	if ($@) {
		die "Line $line: Unknown or unsupported style '$copy'";
	}

	return $string;
}

sub parse_boolean {
	my $class  = shift;
	my $line   = shift;
	my $string = shift;
	unless ( $string eq '0' or $string eq '1' ) {
		die "Line $line: Boolean value '$string' is not 0 or 1";
	}
	return $string;
}





######################################################################
# Compilation and Application

sub apply {
	my $self     = shift;
	my $window   = shift;
	my $sequence = undef;
	if ( Params::Util::_INSTANCE( $window, 'Padre::Wx::Editor' ) ) {
		my $document = $window->{Document} or return;
		my $mimetype = $document->mimetype or return;
		$sequence = $self->mime($mimetype);

		# Reset the editor style
		$self->clear($window);
	} else {
		$sequence = $self->{mime}->{gui} or return;
	}

	# Apply the precalculated style methods
	my $i = 0;
	while ( my $method = $$sequence[ $i++ ] ) {
		my $params = $$sequence[ $i++ ];
		$window->$method(@$params);
	}

	return 1;
}

sub clear {
	my $self   = shift;
	my $editor = shift;
	my $config = $editor->config;

	# Clears settings back to the editor configuration defaults
	# To do this we flush absolutely everything and then apply
	# the basic font settings.
	$editor->StyleResetDefault;

	# Reset the font from configuration (which Scintilla considers part of
	# the "style" but Padre doesn't allow to be changed as a "style")
	my $font = Wx::Font->new( 10, Wx::TELETYPE, Wx::NORMAL, Wx::NORMAL );
	if ( defined Params::Util::_STRING( $config->editor_font ) ) {
		$font->SetNativeFontInfoUserDesc( $config->editor_font );
	}
	$editor->SetFont($font);
	$editor->StyleSetFont( Wx::wxSTC_STYLE_DEFAULT, $font );

	# Clear all styles back to the default
	$editor->StyleClearAll;

	return 1;
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
