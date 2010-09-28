package Perl::Critic::Policy::Modules::ProhibitWarning;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.05';

Readonly::Scalar my $DESC => q{"use warning"};
Readonly::Scalar my $EXPL => 'You need to write use warnings (with an s at the end) and not use warning.';

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGHEST   }

sub default_themes       { return qw( core bugs ) }

sub applies_to           { return 'PPI::Token::Word'  }

sub violates {
        my ( $self, $elem, undef ) = @_;
        return if $elem ne 'use';
        return if ! is_function_call($elem);
        my $sib = $elem->snext_sibling() or return;
        return if $sib ne 'warning';
        return $self->violation( $DESC, $EXPL, $elem );
}

1;
