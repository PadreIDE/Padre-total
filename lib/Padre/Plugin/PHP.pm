package Padre::Plugin::PHP;

use warnings;
use strict;

our $VERSION = '0.01';

use base 'Padre::Plugin';
use Wx ':everything';

sub padre_interfaces {
	'Padre::Plugin'   => 0.26,
	'Padre::Document' => 0.21,
}

sub registered_documents {
	'application/x-php' => 'Padre::Document::PHP',
}

sub menu_plugins_simple {
    my $self = shift;
    
	return ('PHP' => [
	    'About',   sub { $self->about },
	]);
}

sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName(__PACKAGE__);
	$about->SetDescription(
		"This plugin currently provides naive syntax highlighting for PHP files\n"
	);
	$about->SetVersion($VERSION);
	Wx::AboutBox( $about );
	return;
}


1;
__END__

=head1 NAME

Padre::Plugin::PHP - L<Padre> and PHP

=head1 AUTHOR

Gabor Szabo, C<< <szabgab at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Gabor Szabo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
