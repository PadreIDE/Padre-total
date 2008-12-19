package Padre::Plugin::Perl6;

use 5.010;
use strict;
use warnings;
use English;
use Carp;
use feature qw(say);
use IO::File;
use File::Temp;

our $VERSION = '0.22';

use URI::file;
use Syntax::Highlight::Perl6;

use Padre::Wx ();
use base 'Padre::Plugin';

=head1 NAME

Padre::Plugin::Perl6 - Experimental Padre plugin for Perl6

=head1 SYNOPSIS

After installation when you run Padre there should be a menu option Plugins/Perl6.

=head1 COPYRIGHT

Copyright 2008 Gabor Szabo. L<http://www.szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

sub padre_interfaces {
	'Padre::Plugin'         => 0.20,
}


sub menu_plugins_simple {
	my $self = shift;
	'Perl 6' => [
		'About' => sub { $self->show_about },
		'Export HTML' => sub { $self->export_html },
	];
}

sub registered_documents {
	'application/x-perl6'    => 'Padre::Document::Perl6',
}


sub show_about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Perl6");
	$about->SetDescription(
		"Perl6 syntax highlighting that is based on Syntax::Highlight::Perl6\n"
	);
	#$about->SetVersion($Padre::VERSION);
	Wx::AboutBox( $about );
	return;
}


sub export_html {
	my ($main) = @_;
	
	my $text = Padre::Documents->current->text_get() // '';
	
  my $p = Syntax::Highlight::Perl6->new(
    text => $text,
  );
  
  my $snippet_html;
	eval {
		$snippet_html = $p->snippet_html;
		1;
	};
	
	if($EVAL_ERROR) {
		say 'Parsing error, bye bye ->export_html';
		return;
	}

	my $tmp = File::Temp->new(SUFFIX => '.html');
	$tmp->unlink_on_destroy(0);
	my $filename = $tmp->filename;
	
	print $tmp $snippet_html;
	close $tmp
		or croak "Could not close $filename";

	my $uri = URI::file->new($filename);
	Wx::LaunchDefaultBrowser($uri);	
}


1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
