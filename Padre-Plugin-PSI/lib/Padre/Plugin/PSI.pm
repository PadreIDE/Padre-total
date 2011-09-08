package Padre::Plugin::PSI;
use strict;
use warnings;
use 5.008;

our $VERSION = '0.01';

use Padre::Wx ();

use base 'Padre::Plugin';

=head1 NAME

Padre::Plugin::PSI - Experimental Padre plugin written in Perl 6

=head1 SYNOPSIS

After installation when you run Padre there should be a menu option Plugins/PSI
with several submenues.

About is just some short explanation

=head1 COPYRIGHT

Copyright 2009 Gabor Szabo. L<http://www.szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

sub padre_interfaces {
	return 'Padre::Plugin' => '0.91',;
}


sub plugin_name {
	'PSI';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About'            => \&about,
		'Size of document' => \&len_in_rakudo,
	];
}

#sub registered_documents {
#}

sub plugin_enable {
	my $self = shift;

	require Inline::Rakudo;
	my $rakudo = Inline::Rakudo->rakudo;

	return if not $rakudo;

	my $code = <<'END_PIR';
sub len($str) {
	return $str.chars;
}
END_PIR

	$rakudo->run_code($code);


	return 1;
}



sub len_in_rakudo {
	my ($main) = @_;

	my $rakudo = Inline::Rakudo->rakudo;
	if ( not $rakudo ) {
		Wx::MessageBox( "Rakudo is not available", "No luck", Wx::wxOK | Wx::wxCENTRE, $main );
		return;
	}
	my $doc = Padre::Current->document;
	my $str = "No file is open";
	if ($doc) {
		$str = "Number of characters in the current file: " . $rakudo->run_sub( 'len', $doc->text_get );
	}

	Wx::MessageBox( "From Rakudo: $str", "Worksforme", Wx::wxOK | Wx::wxCENTRE, $main );
	return;
}

sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName(__PACKAGE__);
	$about->SetDescription( "Experimental Plugin written in Perl 6\n" );
	$about->SetVersion($VERSION);
	Wx::AboutBox($about);
	return;
}

1;

# Copyright 2009 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
