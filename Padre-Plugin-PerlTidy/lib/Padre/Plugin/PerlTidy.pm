package Padre::Plugin::PerlTidy;

use 5.008002;
use strict;
use warnings;
use File::Spec     ();
use File::Basename ();
use Params::Util   ();
use Padre::Current ();
use Padre::Wx      ();
use Padre::Plugin  ();
use FindBin qw($Bin);

our $VERSION = 0.19;
our @ISA     = 'Padre::Plugin';

# This constant is used when storing and restoring the cursor position.
# Keep it small to limit resource use.
use constant SELECTIONSIZE => 40;

sub padre_interfaces {
	return (
		'Padre::Plugin'   => '0.43',
		'Padre::Config'   => '0.54',
		'Padre::Wx::Main' => '0.86',
	);
}

sub plugin_name {
	return Wx::gettext('Perl Tidy');
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext("Tidy the active document\tAlt+Shift+F") => sub {
			$self->tidy_document;
		},
		Wx::gettext("Tidy the selected text\tAlt+Shift+G") => sub {
			$self->tidy_selection;
		},
		'---' => undef,
		Wx::gettext('Export active document to HTML file') => sub {
			$self->export_document;
		},
		Wx::gettext('Export selected text to HTML file') => sub {
			$self->export_selection;
		},
		'---'                         => undef,
		Wx::gettext('Configure tidy') => sub {
			$self->configure_tidy;
		},
	];
}

my $over_ride;





######################################################################
# Menu Handlers

sub tidy_document {
	my $self     = shift;
	my $current  = $self->current;
	my $main     = $current->main;
	my $document = $current->document;
	my $text     = $document->text_get;

	# Tidy the entire current document
	$over_ride = 0;
	my $perltidyrc = $self->_which_tidyrc( $main, undef );
	my $tidy = $self->_tidy( $main, $current, $text, $perltidyrc );
	unless ( defined Params::Util::_STRING($tidy) ) {
		return;
	}

	# Overwrite the entire document
	my ( $regex, $start ) = $self->_store_cursor_position($current);
	$document->text_set($tidy);
	$self->_restore_cursor_position( $current, $regex, $start );
}

sub tidy_selection {
	my $self     = shift;
	my $current  = $self->current;
	my $main     = $current->main;
	my $text     = $current->text;

	# Tidy the current selected text
	$over_ride = 0;
	my $perltidyrc = $self->_which_tidyrc( $main, undef );
	my $tidy = $self->_tidy( $main, $current, $text, $perltidyrc );
	unless ( defined Params::Util::_STRING($tidy) ) {
		return;
	}

	# If the selected text does not have a newline at the end,
	# trim off any that Perl::Tidy has added.
	unless ( $text =~ /\n\z/ ) {
		$tidy =~ s{\n\z}{};
	}

	# Overwrite the selected text
	$current->editor->ReplaceSelection($tidy);
}

sub export_selection {
	my $self    = shift;
	my $current = $self->current;
	my $main    = $current->main;
	my $text    = $current->text;
	$self->_export( $main, $text );
	return;
}

sub export_document {
	my $self    = shift;
	my $current = $self->current;
	my $main    = $current->main;
	my $text    = $current->text_get;
	$self->_export( $main, $text );
	return;
}

sub configure_tidy {
	require Padre::Plugin::PerlTidy::Dialog;
	Padre::Plugin::PerlTidy::Dialog->new;
	return;
}





######################################################################
# Support Methods

sub _tidy {
	my $self       = shift;
	my $main       = shift;
	my $current    = shift;
	my $source     = shift;
	my $perltidyrc = shift;
	my $document   = $current->document;

	# Check for problems
	unless ( defined $source ) {
		return;
	}
	unless ( $document->isa('Padre::Document::Perl') ) {
		$main->error( Wx::gettext('Document is not a Perl document') );
		return;
	}

	my $destination = undef;
	my $errorfile   = undef;
	my %tidyargs    = (
		argv        => \'-nse -nst',
		source      => \$source,
		destination => \$destination,
		errorfile   => \$errorfile,
	);
	if ($over_ride) {
		$tidyargs{'perltidyrc'} = $perltidyrc;
	}

	my $output;
	if ( $main->config->info_on_statusbar ) {
		$main->info( Wx::gettext("Running Tidy, don't forget to save changes.") );
	} else {

		#Make sure output is visible...
		$main->show_output(1);
		$output = $main->output;
	}

	#	CLAUDIO: This code breaks the plugin, temporary disabled.
	#	Have a look at Perl::Tidy line 126 for details: expecting a reference related to a file and not Wx::CommandEvent).
	#	Talk to El_Che for more info.
	#	if (not $perltidyrc) {
	#		$perltidyrc = $document->project->config->config_perltidy;
	#	}
	#	if ($perltidyrc) {
	#		$tidyargs{perltidyrc} = $perltidyrc;
	#		$output->AppendText("Perl::Tidy running with project configuration $perltidyrc\n");
	#	} else {
	#		$output->AppendText("Perl::Tidy running with default or user configuration\n");
	#	}

	# TODO: suppress the senseless warning from PerlTidy
	eval {
		require Perl::Tidy;
		Perl::Tidy::perltidy(%tidyargs);
	};
	if ($@) {
		$main->error( Wx::gettext("PerlTidy Error") . ":\n" . $@ );
		return;
	}

	if ( defined $errorfile ) {
		$main->show_output(1);
		$output = $main->output;
		my $filename =
			  $document->filename
			? $document->filename
			: $document->get_title;
		my $width = length($filename) + 2;
		$output->AppendText( "\n\n" . "-" x $width . "\n" . $filename . "\n" . "-" x $width . "\n" );
		$output->AppendText("$errorfile\n");
	}

	return $destination;
}

sub _export {
	my $self = shift;
	my $main = shift;
	my $src  = shift;
	return unless defined $src;

	my $doc = $main->current->document;

	if ( !$doc->isa('Padre::Document::Perl') ) {
		$main->error( Wx::gettext('Document is not a Perl document') );
		return;
	}

	my $filename = $self->_get_filename($main);
	return unless defined $filename;

	my ( $output, $error );
	my %tidyargs = (
		argv        => \'-html -nnn -nse -nst',
		source      => \$src,
		destination => $filename,
		errorfile   => \$error,
	);

	# Make sure output window is visible...
	$main->show_output(1);
	$output = $main->output;

	if ( my $tidyrc = $doc->project->config->config_perltidy ) {
		$tidyargs{perltidyrc} = $tidyrc;
		$output->AppendText( "Perl\::Tidy running with project-specific configuration $tidyrc\n" );
	} else {
		$output->AppendText("Perl::Tidy running with default or user configuration\n");
	}

	# TODO: suppress the senseless warning from PerlTidy
	eval {
		require Perl::Tidy;
		Perl::Tidy::perltidy(%tidyargs);
	};
	if ($@) {
		$main->error( Wx::gettext("PerlTidy Error") . ":\n" . $@ );
		return;
	}

	if ( defined $error ) {
		my $width = length( $doc->filename ) + 2;
		my $main  = Padre::Current->main;

		$output->AppendText( "\n\n" . "-" x $width . "\n" . $doc->filename . "\n" . "-" x $width . "\n" );
		$output->AppendText("$error\n");
		$main->show_output(1);
	}

	return;
}

sub _get_filename {
	my $self        = shift;
	my $main        = shift;
	my $doc         = $main->current->document or return;
	my $current     = $doc->filename;
	my $default_dir = '';

	if ( defined $current ) {
		$default_dir = File::Basename::dirname($current);
	}

	while (1) {
		my $dialog = Wx::FileDialog->new(
			$main,
			Wx::gettext("Save file as..."),
			$default_dir,
			( $current or $doc->get_title ) . '.html',
			"*.*",
			Wx::wxFD_SAVE,
		);
		if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
			return;
		}
		my $filename = $dialog->GetFilename;
		$default_dir = $dialog->GetDirectory;
		my $path = File::Spec->catfile( $default_dir, $filename );
		if ( -e $path ) {
			return $path
				if $main->yes_no(
				Wx::gettext("File already exists. Overwrite it?"),
				Wx::gettext("Exist")
				);
		} else {
			return $path;
		}
	}
}

# parameter: $main, compiled regex
sub _restore_cursor_position {
	my $self    = shift;
	my $current = shift;
	my $regex   = shift;
	my $start   = shift;
	my $editor  = $current->editor;
	my $text    = $editor->GetTextRange(
		( $start - SELECTIONSIZE ) > 0 ? $start - SELECTIONSIZE
		: 0,
		( $start + SELECTIONSIZE < $editor->GetLength ) ? $start + SELECTIONSIZE
		: $editor->GetLength
	);
	eval {
		if ( $text =~ /($regex)/ ) {
			my $pos = $start + length $1;
			$editor->SetCurrentPos($pos);
			$editor->SetSelection( $pos, $pos );
		}
	};
	$editor->goto_line_centerize( $editor->GetCurrentLine );
	return;
}

# parameter: $current
# returns: compiled regex, start position
# compiled regex is /^./ if no valid regex can be reconstructed.
sub _store_cursor_position {
	my $self    = shift;
	my $current = shift;
	my $editor  = $current->editor;
	my $pos     = $editor->GetCurrentPos;

	my $start;
	if ( ( $pos - SELECTIONSIZE ) > 0 ) {
		$start = $pos - SELECTIONSIZE;
	} else {
		$start = 0;
	}

	my $prefix = $editor->GetTextRange( $start, $pos );
	my $regex;
	eval {

		# Escape non-word chars
		$prefix =~ s/(\W)/\\$1/gm;

		# Replace whitespace by regex \s+
		$prefix =~ s/(\\\s+)/(\\s+|\\r*\\n)*/gm;

		$regex = qr{$prefix};
	};
	if ($@) {
		$regex = qw{^.};
		print STDERR @_;
	}
	return ( $regex, $start );
}

sub plugin_disable {
	my $self = shift;
	$self->unload('Padre::Plugin::PerlTidy::Dialog');
	return;
}

#######
# method _which_tidyrc
# Pick the revelant tidyrc file
#######
sub _which_tidyrc {
	my $self       = shift;
	my $main       = shift;
	my $perltidyrc = shift;

	# perl tidy Padre/tools
	if ( $ENV{'PADRE_DEV'} ) {
		eval {
			$perltidyrc = File::Spec->catfile( $Bin, '../../tools/perltidyrc' );
		};
		if ( -e $perltidyrc ) {
			$over_ride = 1;
			return $perltidyrc;

		} else {
			$main->config->info_on_statusbar(0);
			$main->info( Wx::gettext("You need to install from SVN Padre/tools.") );
			print " here we are \n";
			Wx::MessageBox(
				Wx::gettext("You need to install from SVN Padre/tools."),
				Wx::gettext("tools/perltidyrc missing"),
				Wx::wxCANCEL,
				$main,
			);
			$main->config->info_on_statusbar(1);
		}
	}

	return;
}

1;

=pod

=head1 NAME

Padre::Plugin::PerlTidy - Format perl files using Perl::Tidy

=head1 DESCRIPTION

This is a simple plugin to run L<Perl::Tidy> on your source code.

Currently there are no customisable options (since the Padre plugin system
doesn't support that yet) - however Perl::Tidy will use your normal .perltidyrc
file if it exists (see Perl::Tidy documentation).

=head1 METHODS

=head2 padre_interfaces

Indicates our compatibility with Padre.

=head2 plugin_name

A simple accessor for the name of the plugin.

=head2 menu_plugins_simple

Menu items for this plugin.

=head2 tidy_document

Runs Perl::Tidy on the current document.

=head2 export_document

Export the current document as html.

=head2 tidy_selection

Runs Perl::Tidy on the current code selection.

=head2 export_selection

Export the current code selection as html.

=cut
