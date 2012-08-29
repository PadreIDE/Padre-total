package Padre::Plugin::Nopaste::Services;

use v5.10;
use strict;
use warnings;

use English qw( -no_match_vars ); # Avoids regex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

# use feature 'unicode_strings';
our $VERSION = '0.04';

# use Carp::Always;
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


1;

__END__

=pod

=head1 NAME

Padre::Plugin::Nopaste::Services - Check spelling in Padre, The Perl IDE.

=head1 VERSION

version  0.04

=head1 DESCRIPTION

This module handles the Preferences dialogue window that is used to set your 
chosen dictionary and preferred language.


=head1 ATTRIBUTES

=over 2

=item *	Codepeek
=item *	Debian
=item *	Gist
=item *	PastebinCom
=item *	Pastie
=item *	Shadowcat
=item *	Snitch
=item *	Ubuntu
=item *	channels
=item *	servers
=item *	ssh

=back

=head1 BUGS AND LIMITATIONS

Throws an info on the status bar if you try to select a language if dictionary not installed

=head1 DEPENDENCIES



=head1 SEE ALSO

For all related information (bug reporting, source code repository,
etc.), refer to L<Padre::Plugin::Nopaste>.

=head1 AUTHOR

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 kevin dawson, all rights reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

