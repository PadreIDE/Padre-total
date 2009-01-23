package Padre::Plugin::SpellCheck;

use warnings;
use strict;

our $VERSION = '0.01';

use base 'Padre::Plugin';
use Padre::Current ();

sub padre_interfaces {
	'Padre::Plugin' => '0.26',
}

sub menu_plugins_simple {
	return ('Spell Check' => [
		'Run it', 'spell_check',
	]);
}

sub spell_check {
	my ( $self ) = shift;
	
	my $speller;
	eval {
		require Text::Aspell;
		$speller = Text::Aspell->new;
		$speller->set_option('sug-mode', 'fast');
		# TODO, configurable later
		$speller->set_option('lang','en_US');
	};
	if ( $@ ) {
		Padre::Current->main->error( $@ );
		return;
	}
	
	my $src  = Padre::Current->text;
	my $doc  = Padre::Current->document;
	my $text = $src ? $src : $doc->text_get;
	
	Padre::Current->main->show_output(1);
	Padre::Current->main->output->clear;
	my $has_bad = 0;
	
	foreach my $word ( split /\b/, $text ){
		# Skip empty strings and non-spellable words
		next unless defined $word;
		next unless ($word =~ /^\p{L}+$/i);
		next if $speller->check( $word ) || $word =~ /^\d+$/;
		my @suggestions = $speller->suggest( $word );
		Padre::Current->main->output->AppendText("wrong $word, suggest " . join(', ', @suggestions));
		$has_bad = 1;
	}
	
	unless ( $has_bad ) {
		Padre::Current->main->output->AppendText("Everything seems OK around");
	}

	return 1;
}

1;
__END__

=head1 NAME

Padre::Plugin::SpellCheck - Spell Check in Padre

=head1 DESCRIPTION

First of all, you must have "the aspell binary and dictionary" installed

read L<http://search.cpan.org/dist/Text-Aspell/README> for more details

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
