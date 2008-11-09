package Padre::Plugin::Parrot;
use strict;
use warnings;

our $VERSION = '0.16';

use Padre::Wx ();

=head1 NAME

Padre::Plugin::Parrot - Experimental Padre plugin that runs on Parrot

=head1 SYNOPSIS

After installation when you run Padre there should be a menu option Plugins/Parrot.

=head1 COPYRIGHT

Copyright 2008 Gabor Szabo. L<http://www.szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut


my @menu = (
    ["Try Perl5 native",              \&on_try_perl5],
    ["Try PIR using embedded Parrot", \&on_try_pir],
);

sub menu {
    my ($self) = @_;
    return @menu;
}

sub on_try_perl5 {
	my ($main) = @_;
	
	my $doc = Padre::Documents->current;
	my $str = "No file is open";
	if ($doc) {
		$str = "Number of characters in the current file: " . length($doc->text_get);
	}
	
	Wx::MessageBox( "From Perl 5. $str", "Worksforme", Wx::wxOK|Wx::wxCENTRE, $main );
	return;
}

sub on_try_pir {
	my ($main) = @_;
	my $parrot = Padre->ide->parrot;
	if (not $parrot) {
		Wx::MessageBox( "Parrot is not available", "No luck", Wx::wxOK|Wx::wxCENTRE, $main );
		return;
	}
	
my $code = <<END_PIR;
.sub on_try_pir
	.param string code

	.local int count
	count = length code

	.return( count )
.end
END_PIR

	my $eval = $parrot->compile( $code );
	my $sub  = $parrot->find_global('on_try_pir');

	my $doc = Padre::Documents->current;
	my $str = "No file is open";
	if ($doc) {
		my $pmc  = $sub->invoke( 'PS', $doc->text_get );
		$str = "Number of characters in the current file: " . $pmc->get_string;
	}

	Wx::MessageBox( "From Parrot using PIR: $str", "Worksforme", Wx::wxOK|Wx::wxCENTRE, $main );
	return;
}

sub menu_name {
	return "Parrot Experiments";
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
