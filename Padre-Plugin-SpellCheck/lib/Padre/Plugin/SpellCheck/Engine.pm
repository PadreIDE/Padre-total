package Padre::Plugin::SpellCheck::Engine;

use warnings;
use strict;

use Padre::Logger;
use Padre::Unload                          ();
use Text::Aspell ();

use Class::XSAccessor {	
	replace => 1,
	accessors => {
		_ignore    => '_ignore',    # list of words to ignore
		                            # _plugin    => '_plugin',    # ref to spellecheck plugin
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
sub new_old {

	# my ( $class, $plugin, $mimetype ) = @_;
	my ( $class, $mimetype, $iso ) = @_;
	my $self  = {};    # Allocate new memory
	bless $self, $class; # Mark it of the right type
	# my $self = bless {
		# _ignore => {},

		# # _plugin    => $plugin,
		# _utf_chars => 0,
	# }, $class;
	
	$self->_ignore( {} );
	$self->_utf_chars(0);
	
	
	# # create speller object
	my $speller = Text::Aspell->new;

	# # my $config  = $plugin->config;

	# # TODO: configurable later
	$speller->set_option( 'sug-mode', 'normal' );

	# # $speller->set_option( 'lang',     $config->{dictionary} );
	$speller->set_option( 'lang', $iso );

	# #$speller->print_config;  # to STDOUT	
	# # TRACE( "print config info = " . $speller->print_config ) if DEBUG;
	
	# my $speller = Text::SpellChecker->new(text => $text, from_frozen => $serialized_data, lang => $lang)
	
	if ( exists $MIMETYPE_MODE{$mimetype} ) {
		if ( not defined $speller->set_option( 'mode', $MIMETYPE_MODE{$mimetype} ) ) {
			my $err = $speller->errstr;
			warn "Could not set aspell mode '$MIMETYPE_MODE{$mimetype}': $err\n";
		}
	}

	TRACE( $speller->print_config ) if DEBUG;

	$self->_speller($speller);

	return $self;
}
#######
# _init
#######
sub _init {
	# my ( $self, %args ) = @_;
	my ( $self, $mimetype, $iso ) = @_;
	
	$self->_ignore( {} );
	$self->_utf_chars(0);
	# create speller object
	my $speller = Text::Aspell->new;

	# my $config  = $plugin->config;

	# TODO: configurable later
	$speller->set_option( 'sug-mode', 'normal' );

	# $speller->set_option( 'lang',     $config->{dictionary} );
	$speller->set_option( 'lang', $iso );

	#$speller->print_config;  # to STDOUT	
	# TRACE( "print config info = " . $speller->print_config ) if DEBUG;
	
	if ( exists $MIMETYPE_MODE{$mimetype} ) {
		if ( not defined $speller->set_option( 'mode', $MIMETYPE_MODE{$mimetype} ) ) {
			my $err = $speller->errstr;
			warn "Could not set aspell mode '$MIMETYPE_MODE{$mimetype}': $err\n";
		}
	}

	TRACE( $speller->print_config ) if DEBUG;

	$self->_speller($speller);

	return;
}



sub check {
	my ( $self, $text ) = @_;
	my $speller = $self->_speller;
	my $ignore  = $self->_ignore;

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
		if ( $speller->check($word) ) {
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


sub dictionaries {
	my ($self) = @_;
	return grep { $_ =~ /^\w+$/ }
		map { $_->{name} } $self->_speller->dictionary_info;
}

sub ignore {
	my ( $self, $word ) = @_;
	$self->_ignore->{$word} = 1;
}

sub suggestions {
	my ( $self, $word ) = @_;
	return $self->_speller->suggest($word);
}

# -- private methods

#
# FIXME: as soon as STC issues is resolved
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


=item * $engine->ignore( $word );

Tell engine to ignore C<$word> for rest of the spell check.


=item * my @dictionaries = $engine->dictionaries;

Return a (reduced) list of dictionaries installed with aspell. The
names returned are the dictionary locale names (eg C<en_US>). Note
that only plain locales are reported, the variations coming with
aspell are stripped.


=item * my @suggestions = $engine->suggestions( $word );

Return suggestions for C<$word>.



=back

=head1 SEE ALSO

For all related information (bug reporting, source code repository,
etc.), refer to L<Padre::Plugin::SpellCheck>.
=cut
