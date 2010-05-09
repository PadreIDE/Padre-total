package Padre::Plugin::LaTeX;

use warnings;
use strict;

our $VERSION = '0.01';

use base 'Padre::Plugin';
use Padre::Wx ();

sub plugin_name {
	'LaTeX';
}

sub padre_interfaces {
	'Padre::Plugin'   => 0.60,
	'Padre::Document' => 0.60,
}

sub registered_documents {
	'application/x-latex' => 'Padre::Document::LaTeX',
}

sub menu_plugins_simple {
	my $self = shift;
	return ();
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->show_about },

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

sub editor_enable {
	my $self     = shift;
	my $editor   = shift;
	my $document = shift;

	if ( $document->isa('Padre::Document::LaTeX') ) {
		# TODO
	}

	return 1;
}

1;
__END__

=head1 NAME

Padre::Plugin::LaTeX - L<Padre> and LaTeX

=head1 AUTHOR

Zeno Gantner, C<< <zeno.gantner at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Zeno Gantner, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0 itself.

=cut
