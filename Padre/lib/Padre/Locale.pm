package Padre::Locale;

=pod

=head1 NAME

Padre::Locale - Locale support for Padre

=head1 DESCRIPTION

B<Padre::Locale> is a utility library that implements locale and encoding
support for the L<Padre> editor, and serves as an integration point between
the various identifier systems (Wx identifiers, ISO639, RFC3066, RFC4646)

The module implements a collection of public functions that can be called
by various parts of the editor to get locale and encoding information.

None of the functions in B<Padre::Locale> are exported. Because the need
for encoding and locale functionality is very high in a user-facing
application like Padre, the resulting quantity of exports would be very
very high.

Forcing all calls to the functions to be fully referenced assists in
reducing the complexity of the Perl symbol table (saving a small amount of
memory) and serves to improve maintainability, as there can always be
certainty about where a particular function is being called from.

=head1 FUNCTIONS

TO BE COMPLETED

=cut

use 5.008;
use strict;
use warnings;
use List::Util ();
use File::Spec ();

# NOTE: Normally, namespace convention is that modules outside of
# Padre::Wx should not implement anything using Wx modules.
# We make an exception in this case, because we're only using the locale
# logic in Wx, which isn't related to widgets anyway.
use Padre::Util   ('_T');
use Padre::Config ();
use Padre::Wx     ();

use constant DEFAULT  => 'en-gb';
use constant SHAREDIR => File::Spec->rel2abs(
	Padre::Util::sharedir('locale')
);

our $VERSION = '0.28';

# The RFC4646 table is the primary language data table and contains
# mappings from a Padre-supported language to all the relevant data
# about that language.
# According to the RFC all identifiers are case-insensitive, but for
# simplicity (for now) we list them all as lower-case.
my %RFC4646;
BEGIN {
	%RFC4646 = (
		# The default language for Padre is "United Kingdom English"
		# The most common English dialect, used not only in the UK,
		# but also other Commonwealth countries such as Australia,
		# New Zealand, India, and Canada (sort of...)
		# The following entry for it is heavily commented for
		# documentation purposes.
		'en-gb' => {
			# REQUIRED: The gettext msgid for the language.
			gettext    => _T('English (United Kingdom)'),
	
			# REQUIRED: The native name of the language
			utf8text   => 'English (United Kingdom)',
	
			# OPTIONAL: Mapping to ISO 639 language tag.
			# Used by Padre's first-generation locale support
			# This should be lowercase.
			iso639    => 'en',
	
			# OPTIONAL: Mapping to the ISO 3166 country code.
			# This should be uppercase.
			iso3166   => 'GB',
	
			# REQUIRED: The wxWidgets language (integer) identifier.
			# http://docs.wxwidgets.org/stable/wx_languagecodes.html#languagecodes
			wxid      => Wx::wxLANGUAGE_ENGLISH_UK,
	
			# OPTIONAL: Recommended language fallback sequence.
			# This is an ordered list of alternative languages
			# that Padre should try to use if no first-class
			# support is available for this language.
			# This is mainly used to allow closest-dialect support.
			# For example, if full support for "Portugese Portugese"
			# is not available, we first attempt to use
			# "Brazillian Portugese" first, before falling back on
			# "American English" and only then the default.
			# Entries in the fallback list express intent, and
			# they do not need to have an entry in %RFC4646.
			fallback  => [ ],
	
			# OPTIONAL: If this language is an official language with
			# a .po file (except for en-gb of course).
			supported => 1,
		},
	
		# Example entry for an language which is not supported directly,
		# but which Padre is aware of.
		'en-au' => {
			gettext   => _T('English (Australian)'),
			utf8text  => 'English (Australian)',
			iso639    => 'en',
			iso3166   => 'AU',
			wxid      => Wx::wxLANGUAGE_ENGLISH_AUSTRALIA,
			# Even though en-gb is the default language, in this
			# specific case there is a clearly expressed desire for
			# this fallback path.
			# If we are ever forced for technical reasons to move to
			# using en-us as a default, this group would explicitly
			# wish to retain the final fallback to en-gb.
			# NOTE: The en-nz is debatable
			fallback  => [ 'en-nz', 'en-gb' ],
		},
	
		# The fallback entry when Wx can't determine a language
		'x-unknown' => {
			gettext   => _T('Unknown'),
			utf8text  => 'Unknown',
			iso639    => 'en', # For convenience
			iso3166   => undef,
			wxid      => Wx::wxLANGUAGE_UNKNOWN,
			fallback  => [ ],
		},
	
		# The official languages are listed sorted by identifier.
		# NOTE: Please do not populate entries into this list unless
		# you are a native speaker of a particular language and are
		# fully aware of any 
	
		'ar' => {
			gettext   => _T('Arabic'),
			utf8text  => 'عربي',
			iso639    => 'ar',
			iso3166   => undef,
			wxid      => Wx::wxLANGUAGE_ARABIC,
			fallback  => [ ],
			supported => 1,
		},
	
		'de' => {
			gettext   => _T('German'),
			utf8text  => 'Deutsch',
			iso639    => 'de',
			iso3166   => undef,
			wxid      => Wx::wxLANGUAGE_GERMAN,
			fallback  => [ ],
			supported => 1,
		},
	
		'en' => {
			gettext   => _T('English'),
			utf8text  => 'English',
			iso639    => 'en',
			iso3166   => undef,
			wxid      => Wx::wxLANGUAGE_ENGLISH,
			fallback  => [ ],
		},
	
		'en-ca' => {
			gettext   => _T('English (Canada)'),
			utf8text  => 'English (Canada)',
			iso639    => 'en',
			iso3166   => undef,
			wxid      => Wx::wxLANGUAGE_ENGLISH_CANADA,
			fallback  => [ 'en-us', 'en-gb' ],
		},
	
		'en-nz' => {
			gettext   => _T('English (New Zealand)'),
			utf8text  => 'English (New Zealand)',
			iso639    => 'en',
			iso3166   => 'NZ',
			wxid      => Wx::wxLANGUAGE_ENGLISH_NEW_ZEALAND,
			# NOTE: The en-au is debatable
			fallback  => [ 'en-au', 'en-gb' ],
		},
	
		'en-us' => {
			gettext   => _T('English (United States)'),
			utf8text  => 'English (United States)',
			iso639    => 'en',
			iso3166   => 'US',
			wxid      => Wx::wxLANGUAGE_ENGLISH_US,
			fallback  => [ 'en-ca', 'en-gb' ],
		},
	
		'es-ar' => {
			gettext   => _T('Spanish (Argentina)'),
			utf8text  => 'Español (Argentina)',
			iso639    => 'sp',
			iso3166   => 'AR',
			wxid      => Wx::wxLANGUAGE_SPANISH_ARGENTINA,
			fallback  => [ 'es-es', 'en-us' ],
		},
	
		'es-es' => {
			# Simplify until there's another Spanish
			# gettext   => 'Spanish (Spain)',
			# utf8text  => 'Español (de España)',
			gettext   => _T('Spanish'),
			utf8text  => 'Español',
			iso639    => 'sp',
			iso3166   => 'SP',
			wxid      => Wx::wxLANGUAGE_SPANISH,
			fallback  => [ ],
			supported => 1,
		},
	
		'fr-ca' => {
			gettext   => _T('French (France)'),
			utf8text  => 'Français (Canada)',
			iso639    => 'fr',
			iso3166   => 'CA',
			wxid      => Wx::wxLANGUAGE_FRENCH_CANADIAN,
			fallback  => [ 'fr-fr' ],
		},	
	
		'fr-fr' => {
			# Simplify until there's another French
			# gettext   => 'French (France)',
			# utf8text  => 'Français (France)',
			gettext   => _T('French'),
			utf8text  => 'Français',
			iso639    => 'fr',
			iso3166   => 'FR',
			wxid      => Wx::wxLANGUAGE_FRENCH,
			fallback  => [ ],
			supported => 1,
		},
	
		'he' => {
			gettext   => _T('Hebrew'),
			utf8text  => 'עברית',
			iso639    => 'he',
			iso3166   => undef,
			wxid      => Wx::wxLANGUAGE_HEBREW,
			fallback  => [ ],
			supported => 1,
		},
	
		'hu' => {
			gettext   => _T('Hungarian'),
			utf8text  => 'Magyar',
			iso639    => 'hu',
			iso3166   => undef,
			wxid      => Wx::wxLANGUAGE_HUNGARIAN,
			fallback  => [ ],
			supported => 1,
		},
	
		'it-it' => {
			# Simplify until there's another Italian
			# gettext   => 'Italian (Italy)',
			# utf8text  => 'Italiano (Italy)',
			gettext   => _T('Italian'),
			utf8text  => 'Italiano',
			iso639    => 'it',
			iso3166   => 'IT',
			wxid      => Wx::wxLANGUAGE_ITALIAN,
			fallback  => [ ],
			supported => 1,
		},
	
		'ja' => {
			gettext   => _T('Japanese'),
			utf8text  => '日本語',
			iso639    => 'ja',
			iso3166   => undef,
			wxid      => Wx::wxLANGUAGE_JAPANESE,
			fallback  => [ 'en-us' ],
			supported => 1,
		},
	
		'ko' => {
			gettext   => _T('Korean'),
			utf8text  => '한국어',
			iso639    => 'ko',
			iso3166   => 'KR',
			wxid      => Wx::wxLANGUAGE_KOREAN,
			fallback  => [ ],
			supported => 1,
		},
	
		'nl-nl' => {
			# Simplify until there's another Italian
			# gettext   => 'Dutch (Netherlands)',
			# utf8text  => 'Nederlands (Nederlands)',
			gettext   => _T('Dutch'),
			utf8text  => 'Nederlands',
			iso639    => 'nl',
			iso3166   => 'NL',
			wxid      => Wx::wxLANGUAGE_DUTCH,
			fallback  => [ 'nl-be' ],
			supported => 1,
		},
	
		'nl-be' => {
			gettext   => _T('Dutch (Belgium)'),
			utf8text  => 'Nederlands (België)',
			iso639    => 'en',
			iso3166   => 'BE',
			wxid      => Wx::wxLANGUAGE_DUTCH_BELGIAN,
			fallback  => [ 'nl-nl' ],
		},
	
		'pt-br' => {
			gettext   => _T('Portuguese (Brazil)'),
			utf8text  => 'Português (Brasil)',
			iso639    => 'pt',
			iso3166   => 'BR',
			wxid      => Wx::wxLANGUAGE_PORTUGUESE_BRAZILIAN,
			fallback  => [ 'pt-pt' ],
			supported => 1,
		},
	
		'pt-pt' => {
			gettext   => _T('Portuguese (Portugal)'),
			utf8text  => 'Português (Europeu)',
			iso639    => 'pt',
			iso3166   => 'PT',
			wxid      => Wx::wxLANGUAGE_PORTUGUESE,
			fallback  => [ 'pt-br' ],
		},
	
		'ru' => {
			gettext   => _T('Russian'),
			utf8text  => 'Русский',
			iso639    => 'ru',
			iso3166   => undef,
			wxid      => Wx::wxLANGUAGE_RUSSIAN,
			fallback  => [ ],
			supported => 1,
		},
	
		'zh' => {
			gettext   => _T('Chinese'),
			utf8text  => 'Chinese',
			iso639    => 'zh',
			iso3166   => undef,
			wxid      => Wx::wxLANGUAGE_CHINESE,
			fallback  => [ 'zh-cn', 'zh-tw', 'en-us' ],
		},
	
		'zh-cn' => {
			gettext   => _T('Chinese (Simplified)'),
			utf8text  => '中文 (简体)',
			iso639    => 'zh',
			iso3166   => 'CN',
			wxid      => Wx::wxLANGUAGE_CHINESE_SIMPLIFIED,
			fallback  => [ 'en-us' ],
			supported => 1,
		},
	
		'zh-tw' => {
			gettext   => _T('Chinese (Traditional)'),
			utf8text  => '正體中文 (繁體)',
			iso639    => 'zh',
			iso3166   => 'TW',
			wxid      => Wx::wxLANGUAGE_CHINESE_TRADITIONAL,
			fallback  => [ 'zh-cn', 'en-us' ],
		},
	
		# RFC4646 supports the interesting idea of comedy languages.
		# We'll put these at the end :)
		# Mostly what these do is uncover issues that might arise when
		# a language is not supported by various older standards.
		'x-klingon' => {
			gettext   => _T('Klingon'),
			utf8text  => 'Klingon', # TODO Fix this at some point
			iso639    => undef,
			iso3166   => undef,
			wxid      => undef,
			fallback  => [ 'en-gb' ], # Debatable... :)
		},
	);

	# Post-process to find the language each language
	# will actually fall back to.
	foreach my $id ( keys %RFC4646 ) {
		my $lang = $RFC4646{$id};
		$lang->{actual} = List::Util::first {
			$RFC4646{$_}->{supported}
		} ( $id, @{$lang->{fallback}}, DEFAULT );
	}
}

use constant WX => Wx::Locale::GetSystemLanguage();

use constant system_rfc4646 =>
	List::Util::first {
		$RFC4646{$_}->{wxid} == WX
	} grep {
		defined $RFC4646{$_}->{wxid}
	} sort keys %RFC4646;





#####################################################################
# Locale 2.0 Implementation

# Find the rfc4646 to use by default
sub rfc4646 {
	my $config = Padre::Config->read;
	my $locale = $config->locale;
	
	if ( $locale and not $RFC4646{$locale} ) {
		# Bad or unsupported configuration
		$locale = undef;
	}

	# Try for the system default
	$locale ||= system_rfc4646;

	# Use the fallback default
	$locale ||= DEFAULT;

	# Return supported language for this language
	return $RFC4646{$locale}->{actual};
}

# Given a rfc4646 identifier, sets the language globally
# and returns the relevant Wx::Locale object.
sub object {
	my $id     = rfc4646();
	my $lang   = $RFC4646{$id}->{wxid};
	my $locale = Wx::Locale->new($lang);
	$locale->AddCatalogLookupPathPrefix(
		Padre::Util::sharedir('locale')
	);
	unless ( $locale->IsLoaded($id) ) {
		my $file = Padre::Util::sharefile('locale', $id) . '.mo';
		$locale->AddCatalog($id) if -f $file;
	}
	return $locale;
}

sub menu_view_languages {
	return map {
		$_ => Wx::gettext($RFC4646{$_}->{gettext})
	} grep {
		$RFC4646{$_}->{supported}
	} sort keys %RFC4646;
}





#####################################################################
# Encoding Support

sub encoding_system_default {
	my $encoding;
	if ( Padre::Util::MAC ) {
		# In mac system Wx::Locale::GetSystemEncodingName() couldn't
		# return the name of encoding directly.
		# Use LC_CTYPE to guess system default encoding.
		require POSIX;
		my $loc = POSIX::setlocale(POSIX::LC_CTYPE());
		if ( $loc =~ m/^(C|POSIX)/i ) {
			$encoding = 'ascii';
		} elsif ( $loc =~ /\./ ) {
			my ($language, $codeset) = split /\./, $loc;
			$encoding = $codeset;
		}

	} elsif ( Padre::Util::WIN32 ) {
		# In windows system Wx::Locale::GetSystemEncodingName() returns
		# like ``windows-1257'' and it matches as ``cp1257''
		# refer to src/common/intl.cpp
		$encoding = Wx::Locale::GetSystemEncodingName();
		$encoding =~ s/^windows-/cp/i;

	} elsif ( Padre::Util::UNIX ) {
		$encoding = Wx::Locale::GetSystemEncodingName();
		unless ( $encoding ) {
			# this is not a usual case, but...
			require POSIX;
			my $loc = POSIX::setlocale(POSIX::LC_CTYPE());
			if ($loc =~ m/^(C|POSIX)/i) {
				$encoding = 'ascii';
			} elsif ($loc =~ /\./) {
				my ($language, $codeset) = split /\./, $loc;
				$encoding = $codeset;
			}
		}

	} else {
		$encoding = Wx::Locale::GetSystemEncodingName();
	}

	unless ( $encoding ) {
		# fail to get system default encoding
		warn "Could not find system($^O) default encoding. "
			. "Please check it manually and report your environment to the Padre development team.";
		return;
	}

	return $encoding;
}

sub encoding_from_string {
	my $content = shift;

	# FIXME
	# This is a just heuristic approach. Maybe there is a better way. :)
	# Japanese and Chinese have to be tested. Only Korean is tested.
	#
	# If locale of config is one of CJK, then we could guess more correctly.
	# Any type of locale which is supported by Encode::Guess could be added.
	# Or, we'll use system default encode setting
	# If we cannot get system default, then forced it to set 'utf-8'
	my $default  = '';
	my @guess    = ();
	my $encoding = '';
	my $language = rfc4646();
	if ($language eq 'ko') {      # Korean
		@guess = qw/utf-8 euc-kr/;
	} elsif ($language eq 'ja') { # Japan (not yet tested)
		@guess = qw/utf-8 iso8859-1 euc-jp shiftjis 7bit-jis/;
	} elsif ($language =~ /^zh/ ) { # Chinese (not yet tested)
		@guess = qw/utf-8 iso8859-1 euc-cn/;
	} else {
		$default ||= encoding_system_default();
		@guess = ( $default ) if $default;
	}

	require Encode::Guess;
	my $guess = Encode::Guess::guess_encoding($content, @guess);
	unless ( defined $guess ) {
		$guess = ''; # to avoid warnings
	}

	# Wow, nice!
	if ( ref($guess) and ref($guess) =~ m/^Encode::/ ) {
		$encoding = $guess->name;

	# utf-8 is in suggestion
	} elsif ( $guess =~ m/utf8/ ) {
		$encoding = 'utf-8';

	# Choose from suggestion
	} elsif ( $guess =~ m/or/ ) {
		my @suggest_encodings = split /\sor\s/, "$guess";
		$encoding = $suggest_encodings[0];

	# Use system default
	} else {
		$default ||= encoding_system_default();
		$encoding = $default;
	}

	unless ( $encoding ) {
		# Failed to guess encoding from contents
		warn "Could not find encoding. Defaulting to 'utf-8'. "
			. "Please check it manually and report to the Padre development team.";
		$encoding = 'utf-8';
	}

	return $encoding;
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
