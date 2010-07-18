package Padre::Plugin::LaTeX;

use warnings;
use strict;

our $VERSION = '0.02';

use base 'Padre::Plugin';
use Padre::Wx ();

sub plugin_name {
	'LaTeX';
}

sub padre_interfaces {
	'Padre::Plugin'   => 0.65,
	'Padre::Document' => 0.65,
}

sub registered_documents {
	'application/x-latex' => 'Padre::Document::LaTeX',
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('About')             => sub { $self->show_about },
		Wx::gettext('Create/Update PDF') => sub { $self->create_pdf },
		Wx::gettext('View PDF')          => sub { $self->view_pdf   },
		Wx::gettext('Run BibTeX')        => sub { $self->run_bibtex },

		# 'Another Menu Entry' => sub { $self->about },
		# 'A Sub-Menu...' => [
		#     'Sub-Menu Entry' => sub { $self->about },
		# ],
	];
}

#####################################################################
# Custom Methods

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName('LaTeX Plug-in');
	my $authors     = 'Zeno Gantner';
	my $description = Wx::gettext( <<'END' );
Copyright 2010 %s
This plug-in is free software; you can redistribute it and/or modify it under the same terms as Padre.
END
	$about->SetDescription( sprintf($description, $authors) );

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

sub create_pdf {
	my $self = shift;

	my $pdflatex = 'pdflatex -interaction nonstopmode -file-line-error';

        my $main     = $self->main;        
        my $doc      = $main->current->document;
	my $tex_dir  = $doc->dirname;
	my $tex_file = $doc->get_title;

	if ( !$doc->isa('Padre::Document::LaTeX') ) {
		$main->message(Wx::gettext('Creating PDF files is only supported for LaTeX documents.'));
		return;
	}

	# TODO autosave (or ask)
	
	chdir $tex_dir;
	my $output_text = `$pdflatex $tex_file`;
	$self->_output($output_text);
	
	return;	
}

sub run_bibtex {
	my $self = shift;

	my $bibtex = 'bibtex';

        my $main     = $self->main;        
        my $doc      = $main->current->document;
        
        my $tex_dir  = $doc->dirname;
	my $aux_file = $doc->filename;
	$aux_file =~ s/\.tex/.aux/;

	if ( !$doc->isa('Padre::Document::LaTeX') ) {
		$main->message(Wx::gettext('Running BibTeX is only supported for LaTeX documents.'));
		return;
	}

	# TODO autosave (or ask)
	
	chdir $tex_dir;
	my $output_text = `$bibtex $aux_file`;
	$self->_output($output_text);
	
	return;	
}

sub view_pdf {
	my $self = shift;

        my $main = $self->main;        
        my $doc  = $main->current->document;

	if ( !$doc->isa('Padre::Document::LaTeX') ) {
		$main->message(Wx::gettext('Viewing PDF files is only supported for LaTeX documents.'));
		return;
	}

	# TODO find PDF viewer from system settings
	my $pdf_viewer = 'evince';
	
	my $pdf_file = $doc->filename;	
	$pdf_file =~ s/\.tex$/.pdf/;
	
	if (! -f $pdf_file) {
		
	}
	
	system "$pdf_viewer $pdf_file &";
	# TODO check for errors
	
	return;
}


sub editor_enable {
	my $self     = shift;
	my $editor   = shift;
	my $document = shift;

	if ( $document->isa('Padre::Document::LaTeX') ) {
		# TODO
	}

	return 1;
}

sub _output {
	my ( $self, $text ) = @_;
	my $main = $self->main;
	
	$main->show_output(1);
	$main->output->clear;
	$main->output->AppendText($text);
}


1;
__END__

=head1 NAME

Padre::Plugin::LaTeX - L<Padre> and LaTeX

=head1 AUTHOR

Zeno Gantner, C<< <ZENOG at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Zeno Gantner, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0 itself.

=cut
