package Padre::Plugin::Nopaste::Services;

use v5.10;
use strict;
use warnings;

use English qw( -no_match_vars ); # Avoids regex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

# use feature 'unicode_strings';
our $VERSION = '0.4';

use Carp::Always;
use Padre::Unload ();
use Moo;

# has 'servers' => (
	# is      => 'ro',
	# default => sub {
		# my $self = shift;

		# return {
			# Codepeek    => 1,
			# Debian      => 1,
			# Gist        => 1,
			# PastebinCom => 1,
			# Pastie      => 1,
			# Shadowcat   => 1,
			# Snitch      => 1,
			# Ubuntu      => 1,
			# ssh         => 1,
		# };
	# },
# );
has 'servers' => (
	is      => 'ro',
	default => sub {
		my $self = shift;

		return [
			'Codepeek',
			'Debian',
			'Gist',
			'PastebinCom',
			'Pastie',
			'Shadowcat',
			'Snitch',
			'Ubuntu',
			'ssh',
		];
	},
);

has 'channels' => (
	is      => 'ro',
	default => sub {
		my $self = shift;

		return {
			'#angerwhale'      => 1,
			'#axkit-dahut'     => 1,
			'#catalyst'        => 1,
			'#catalyst-dev'    => 1,
			'#cometd'          => 1,
			'#dbix-class'      => 1,
			'#distzilla'       => 1,
			'#handel'          => 1,
			'#iusethis'        => 1,
			'#killtrac'        => 1,
			'#london.pm'       => 1,
			'#miltonkeynes.pm' => 1,
			'#moose'           => 1,
			'#p5p'             => 1,
			'#padre'           => 1,
			'#perl'            => 1,
			'#perl-help'       => 1,
			'#perlde'          => 1,
			'#pita'            => 1,
			'#poe'             => 1,
			'#reaction'        => 1,
			'#rt'              => 1,
			'#soap-lite'       => 1,
			'#tt'              => 1,
		};
	},
);
has 'Codepeek' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);
has 'Debian' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);
has 'Gist' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);
has 'PastebinCom' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);
has 'Pastie' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);
has 'Shadowcat' => (
	is      => 'ro',
	default => sub {
		my $self = shift;

		return [
			'#angerwhale',
			'#axkit-dahut',
			'#catalyst',
			'#catalyst-dev',
			'#cometd',
			'#dbix-class',
			'#distzilla',
			'#handel',
			'#iusethis',
			'#killtrac',
			'#london.pm',
			'#miltonkeynes.pm',
			'#moose',
			'#p5p',
			'#padre',
			'#perl',
			'#perl-help',
			'#perlde',
			'#pita',
			'#poe',
			'#reaction',
			'#rt',
			'#soap-lite',
			'#tt',
		];
	},
);
has 'Snitch' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);
has 'Ubuntu' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);
has 'ssh' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);

sub check_server {
	my $self   = shift;
	my $server = shift;
	return $self->servers->{$server};
}

sub shadowcat {
	my $self    = shift;
	my $channel = shift;

	return $self->channels->{$channel};
}


1;

__END__
