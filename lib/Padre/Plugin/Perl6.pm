# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
package Padre::Plugin::Perl6;

use 5.010;
use strict;
use warnings;
use English;
use Carp;
use feature qw(say switch);
use IO::File;
use File::Temp;

our $VERSION = '0.01';

use URI::file;
use Syntax::Highlight::Perl6;
use Readonly;

use Padre::Wx ();
use base 'Padre::Plugin';

Readonly my $FULL_HTML    => 'full_html';
Readonly my $SIMPLE_HTML  => 'simple_html';
Readonly my $SNIPPET_HTML => 'snippet_html';

sub padre_interfaces {
	'Padre::Plugin'         => 0.20,
}


sub menu_plugins_simple {
	my $self = shift;
	'Perl 6' => [
		'Export Full HTML' => sub { $self->export_html($FULL_HTML); },
		'Export Simple HTML' => sub { $self->export_html($SIMPLE_HTML); },
		'Export Snippet HTML' => sub { $self->export_html($SNIPPET_HTML); },
		'About' => sub { $self->show_about },
	];
}

sub registered_documents {
	'application/x-perl6'    => 'Padre::Document::Perl6',
}


sub show_about {
	my ($main) = @ARG;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Perl6");
	$about->SetDescription(
		"Perl6 syntax highlighting that is based on Syntax::Highlight::Perl6\n"
	);
	Wx::AboutBox( $about );
	return;
}

sub export_html {
	my ($self, $type) = @ARG;

	if(!defined Padre::Documents->current) {
		return;
	}

	my $text = Padre::Documents->current->text_get() // '';

  my $p = Syntax::Highlight::Perl6->new(
    text => $text,
		inline_resources => 1, 
  );

  my $html;
	eval {
		given($type) {
			when ($FULL_HTML) { $html = $p->full_html; }
			when ($SIMPLE_HTML) { $html = $p->simple_html; }
			when ($SNIPPET_HTML) { $html = $p->snippet_html; }
			default {
				croak "'$type' should full_html, simple_html or snippet_html";
			}
		}
		1;
	};

	if($EVAL_ERROR) {
		say 'Parsing error, bye bye ->export_html';
		return;
	}

	# create a temporary HTML file
	my $tmp = File::Temp->new(SUFFIX => '.html');
	$tmp->unlink_on_destroy(0);
	my $filename = $tmp->filename;
	print $tmp $html;
	close $tmp
		or croak "Could not close $filename";

	# try to open the HTML file
	my $main   = Padre->ide->wx->main_window;
	$main->setup_editor($filename);
	#$main->refresh_all;

	# launch the HTML file in your default browser
	my $file_url = URI::file->new($filename);
	Wx::LaunchDefaultBrowser($file_url);	
}


1;

__END__

=head1 NAME

Padre::Plugin::Perl6 - Padre plugin for Perl6

=head1 SYNOPSIS

After installation when you run Padre there should be a menu option Plugins/Perl6.

=head1 AUTHOR

Ahmad M. Zawawi, C<< <ahmad.zawawi at gmail.com> >>
Gabor Szabo

=head1 COPYRIGHT

Copyright 2008 Gabor Szabo. L<http://www.szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
