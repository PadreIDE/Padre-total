package Perl::Critic::Policy::RegularExpressions::ProhibitStrangeDelimiters;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.05';

Readonly::Scalar my $DESC => q{Restricting the delimiters of regexes and substitutes to a list of characters};
Readonly::Scalar my $EXPL => 'e.g. allow m/../ and m{..} but not m@..@ or m#..#';

sub supported_parameters {
        return ({
                name => 'allowed_openers',
                description => 'The opening characters that can be used in a regex',
                default_string => '{ /',
                behavior       => 'string list',

        })
}

sub default_severity     { return $SEVERITY_HIGHEST   }

sub default_themes       { return qw( core bugs ) }

sub applies_to           { return 'PPI::Token::Regexp'  }

sub violates {
        my ( $self, $elem, undef ) = @_;
        return if $elem =~ m{^/};
        my $opener = substr($elem, 1,1);
        my $list = $self->{_allowed_openers};
        return if grep { $opener eq $_ } keys %{$list};
        return $self->violation( $DESC, $EXPL, $elem );
        return;
}

1;

=head1 DESCRIPTION

Check for regexes that are using m but changing the characters to one of the unaccaptable characters
parameres = ['{']   # list of acceptable characters
This should fail on   m@/@   or s,abc,def,

=cut
