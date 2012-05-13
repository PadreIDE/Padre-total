package Padre::Plugin::SpellCheck::Engine;

use v5.10;
use warnings;
use strict;

our $VERSION = '1.26';

use Padre::Logger;
use Padre::Unload ();

use Class::XSAccessor {
	replace   => 1,
	accessors => {
		_ignore    => '_ignore',    # list of words to ignore
		_speller   => '_speller',   # real text::aspell object
		_utf_chars => '_utf_chars', # FIXME: as soon as wxWidgets/wxPerl supports
		                            # newer version of STC:
		                            # number of UTF8 characters
		                            # used in calculating current possition
	},
};

my %MIMETYPE_MODE = (
	'application/x-latex' => 'tex',
	'text/html'           => 'html',
	'text/xml'            => 'sgml',
);


#######
# new
#######
sub new {
	my $class = shift;   # What class are we constructing?
	my $self  = {};      # Allocate new memory
	bless $self, $class; # Mark it of the right type
	$self->_init(@_);    # Call _init with remaining args
	return $self;
}


#######
# Method _init
#######
sub _init {
	my ( $self, $mimetype, $iso, $engine ) = @_;

	$self->_ignore( {} );
	$self->_utf_chars(0);

	#just for testing
	# print "Using Text::$engine with language $iso\n";

	# create speller object
	my $speller;
	if ( $engine eq 'Aspell' ) {
		require Text::Aspell;
		$speller = Text::Aspell->new;

		$speller->set_option( 'sug-mode', 'normal' );
		$speller->set_option( 'lang',     $iso );

		if ( exists $MIMETYPE_MODE{$mimetype} ) {
			if ( not defined $speller->set_option( 'mode', $MIMETYPE_MODE{$mimetype} ) ) {
				my $err = $speller->errstr;
				warn "Could not set aspell mode '$MIMETYPE_MODE{$mimetype}': $err\n";
			}
		}

	} else {
		require Text::Hunspell;

		#TODO add some checking
		# You can use relative or absolute paths.
		$speller = Text::Hunspell->new(
			"/usr/share/hunspell/$iso.aff", # Hunspell affix file
			"/usr/share/hunspell/$iso.dic"  # Hunspell dictionary file
		);
	}

	TRACE( $speller->print_config ) if DEBUG;

	$self->_speller($speller);

	return;
}


#######
# Method check
#######
sub check {
	my ( $self, $text ) = @_;
	my $ignore = $self->_ignore;

	# iterate over word boundaries
	while ( $text =~ /(.+?)(\b|\z)/g ) {
		my $word = $1;

		# skip...
		next unless defined $word;             # empty strings
		next unless $word =~ /^\p{Letter}+$/i; # non-spellable words

		# FIXME: when STC issues will be resolved:
		# count number of UTF8 characters in ignored/correct words
		# it's going to be used to calculate relative position
		# of next problematic word
		if ( exists $ignore->{$word} ) {
			$self->_count_utf_chars($word);
			next;
		}

		# if ( $speller->check($word) ) {
		if ( $self->_speller->check($word) ) {
			$self->_count_utf_chars($word);
			next;
		}

		# uncomment when fixed above
		#        next if exists $ignore->{$word};        # ignored words
		#
		#        # check spelling
		#        next if $speller->check( $word );

		# oops! spell mistake!
		my $pos = pos($text) - length($word);

		return $word, $pos;
	}

	# $text does not contain any error
	return;
}

#######
# Method set_ignore_word
#######
sub set_ignore_word {
	my ( $self, $word ) = @_;
	$self->_ignore->{$word} = 1;
	return;
}

#######
# Method get_suggestions
#######
sub get_suggestions {
	my ( $self, $word ) = @_;
	return $self->_speller->suggest($word);
}


#######
#TODO FIXME: as soon as STC issues is resolved
#
sub _count_utf_chars {
	my ( $self, $word ) = @_;

	foreach ( split //, $word ) {
		$self->{_utf_chars}++ if ord($_) >= 128;
	}

	return;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::SpellCheck::Engine - Check spelling in Padre, The Perl IDE.

=head1 VERSION

version 1.26

=head1 PUBLIC METHODS

=head2 Constructor

=over 4

=item my $engine = PPS::Engine->new;

Create a new engine to be used later on.

=back

=head2 Instance methods

=over 4

=item * my ($word, $pos) = $engine->check( $text );

Spell check C<$text> (according to current speller), and return the
first error encountered (undef if no spelling mistake). An error is
reported as the faulty C<$word>, as well as the C<$pos> of the word in
the text (position of the start of the faulty word).

=item * $engine->set_ignore_word( $word );

Tell engine to ignore C<$word> for rest of the spell check.

=item * my @dictionaries = $engine->dictionaries;

Return a (reduced) list of dictionaries installed with aspell. The
names returned are the dictionary locale names (eg C<en_US>). Note
that only plain locales are reported, the variations coming with
aspell are stripped.

=item * my @suggestions = $engine->get_suggestions( $word );

Return suggestions for C<$word>.


=back

=head1 BUGS AND LIMITATIONS

Text::Hunspell hard coded for /usr/share/hunspell/

=head1 DEPENDENCIES

Padre, Class::XSAccessor and either or ( Text::Hunspell or Text::Aspell )

=head1 SEE ALSO

For all related information (bug reporting, source code repository,
etc.), refer to L<Padre::Plugin::SpellCheck>.

=head1 AUTHORS

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>

Fayland Lam E<lt>fayland@gmail.comE<gt>

Jerome Quelin E<lt>jquelin@gmail.comE<gt>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Fayland Lam, Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
