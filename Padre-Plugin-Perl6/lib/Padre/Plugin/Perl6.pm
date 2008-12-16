package Padre::Plugin::Perl6;
use strict;
use warnings;

our $VERSION = '0.22';

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

sub padre_interfacesx {
	'Padre::Plugin'         => 0.20,
}


sub menu_plugins_simple {
	my $self = shift;
	'Perl 6' => [
		About => sub { $self->show_about },
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
		"Experimental Perl6 syntax highlighting\n"
	);
	#$about->SetVersion($Padre::VERSION);
	Wx::AboutBox( $about );
	return;
}


1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
