package Padre::Plugin::HTMLExport;

use warnings;
use strict;

our $VERSION = '0.01';

use File::Basename ();

use base 'Padre::Plugin';
use Wx ':everything';
use Wx::Locale qw(:default);

our %KATE_ALL = (
	'text/x-adasrc'       => 'Ada',
	'text/asm'            => 'Asm6502',
	'text/x-c++src'       => 'Cplusplus',
	'text/css'            => 'CSS',
	'text/x-patch'        => 'Diff',
	'text/eiffel'         => 'Eiffel',
	'text/x-fortran'      => 'Fortran',
	'text/html'           => 'HTML',
	'text/ecmascript'     => 'JavaScript',
	'text/latex'          => 'LaTeX',
	'text/lisp'           => 'Common_Lisp',
	'text/lua'            => 'Lua',
	'text/x-makefile'     => 'Makefile',
	'text/matlab'         => 'Matlab',
	'text/x-pascal'       => 'Pascal',
	'application/x-perl'  => 'Perl',
	'text/x-python'       => 'Python',
	'application/x-php'   => 'PHP_PHP',
	'application/x-ruby'  => 'Ruby',
	'text/x-sql'          => 'SQL',
	'text/x-tcl'          => 'Tcl_Tk',
	'text/vbscript'       => 'JavaScript',
	'text/xml'            => 'XML',
);

sub padre_interfaces {
	'Padre::Plugin' => '0.18',
}

sub menu_plugins_simple {
	'Export Colorful HTML' => [
		'Export HTML', \&export_html,
		'Configure Color', \&configure_color,
	];
}

sub export_html {
	my ( $self ) = @_;

	my $doc     = $self->selected_document or return;
	my $current = $doc->filename;
	my $default_dir;
	if ( defined $current ) {
		$default_dir = File::Basename::dirname($current);
	}

	# ask where to save
	my $save_to_file;
	while (1) {
		my $dialog = Wx::FileDialog->new(
			$self,
			gettext("Save html as..."),
			$default_dir,
			"",
			"*.*",
			Wx::wxFD_SAVE,
		);
		if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
			return 0;
		}
		my $filename = $dialog->GetFilename;
		$default_dir = $dialog->GetDirectory;
		my $path = File::Spec->catfile($default_dir, $filename);
		if ( -e $path ) {
			my $res = Wx::MessageBox(
				gettext("File already exists. Overwrite it?"),
				gettext("Exist"),
				Wx::wxYES_NO,
				$self,
			);
			if ( $res == Wx::wxYES ) {
				$save_to_file = $path;
				last;
			}
		} else {
			$save_to_file = $path;
			last;
		}
	}
	
	# highlight
	my $mimetype = $doc->mimetype;
	unless ( exists $KATE_ALL{$mimetype} ) {
		$self->error("$mimetype is not supported");
		return;
	}
	my $language = $KATE_ALL{$mimetype};
	
	require Syntax::Highlight::Engine::Kate;
	my $hl = Syntax::Highlight::Engine::Kate->new(
		language => $language,
		substitutions => {
		   "<" => "&lt;",
		   ">" => "&gt;",
		   "&" => "&amp;",
		   " " => "&nbsp;",
		   "\t" => "&nbsp;&nbsp;&nbsp;",
		   "\n" => "<BR>\n",
		},
		format_table => {
		   Alert => ["<font color=\"#0000ff\">", "</font>"],
		   BaseN => ["<font color=\"#007f00\">", "</font>"],
		   BString => ["<font color=\"#c9a7ff\">", "</font>"],
		   Char => ["<font color=\"#ff00ff\">", "</font>"],
		   Comment => ["<font color=\"#7f7f7f\"><i>", "</i></font>"],
		   DataType => ["<font color=\"#0000ff\">", "</font>"],
		   DecVal => ["<font color=\"#00007f\">", "</font>"],
		   Error => ["<font color=\"#ff0000\"><b><i>", "</i></b></font>"],
		   Float => ["<font color=\"#00007f\">", "</font>"],
		   Function => ["<font color=\"#007f00\">", "</font>"],
		   IString => ["<font color=\"#ff0000\">", ""],
		   Keyword => ["<b>", "</b>"],
		   Normal => ["", ""],
		   Operator => ["<font color=\"#ffa500\">", "</font>"],
		   Others => ["<font color=\"#b03060\">", "</font>"],
		   RegionMarker => ["<font color=\"#96b9ff\"><i>", "</i></font>"],
		   Reserved => ["<font color=\"#9b30ff\"><b>", "</b></font>"],
		   String => ["<font color=\"#ff0000\">", "</font>"],
		   Variable => ["<font color=\"#0000ff\"><b>", "</b></font>"],
		   Warning => ["<font color=\"#0000ff\"><b><i>", "</b></i></font>"],
		},
	);

	my $title = 'Highlight ' . $doc->filename . ' By Padre::Plugin::HTML::Export';
	my $code = $doc->text_get;
	my $output = "<html>\n<head>\n<title>$title</title>\n</head>\n<body>\n";
	$output .= $hl->highlightText($code);
	$output .= "</body>\n</html>\n";
	
	open(my $fh, '>', $save_to_file);
	print $fh $output;
	close($fh);

	my $ret = Wx::MessageBox(
		"Saved to $save_to_file. Do you want to open it now?",
		gettext("Done"),
		Wx::wxYES_NO|Wx::wxCENTRE,
		$self,
	);
	if ( $ret == Wx::wxYES ) {
		Wx::LaunchDefaultBrowser($save_to_file);
	}
}

sub configure_color {
	my ( $self ) = @_;
	
	$self->error('Not implemented, TODO');
}

1;
__END__

=head1 NAME

Padre::Plugin::HTMLExport - export highlighted HTML in Padre

=head1 SYNOPSIS

	$>padre
	Plugins -> Export Colorful HTML -> 
						  Export HTML
						  Configure Color

=head1 DESCRIPTION

Export a HTML page by using L<Syntax::Highlight::Engine::Kate>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
