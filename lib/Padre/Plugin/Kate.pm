package Padre::Plugin::Kate;
use strict;
use warnings;
use 5.008;

our $VERSION = '0.01';

use Padre::Wx ();

use base 'Padre::Plugin';

=head1 NAME

Padre::Plugin::Kate - Using the Kate syntax highlighter

=head1 SYNOPSIS

=head1 COPYRIGHT

Copyright 2009 Gabor Szabo. L<http://szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut


sub padre_interfaces {
	return 'Padre::Plugin' => 0.26;
}

sub plugin_name {
	'Kate';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->about },
	];
}

sub registered_documents {
	#'text/x-abc' => 'Padre::Plugin::Kate::ABC', 
	'application/x-php' => 'Padre::Plugin::Kate::PHP',
}

sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName(__PACKAGE__);
	$about->SetDescription("Trying to use Syntax::Highlight::Engine::Kate for syntax highlighting\n" );
	$about->SetVersion($VERSION);
	Wx::AboutBox($about);
	return;
}


1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.


