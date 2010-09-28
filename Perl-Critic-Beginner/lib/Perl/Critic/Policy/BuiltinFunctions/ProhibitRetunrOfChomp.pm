package Perl::Critic::Policy::BuiltinFunctions::ProhibitReturnOfChomp;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.05';

Readonly::Scalar my $DESC => q{Calling close without any parameter.};
Readonly::Scalar my $EXPL => q{close; usually closes STDIN, STDOUT or something else you don't want.};

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGHEST   }

sub default_themes       { return qw( core bugs ) }

sub applies_to           { return 'PPI::Token::Word'  }

sub violates {
        my ( $self, $elem, undef ) = @_;
        return if $elem ne 'chomp';
        my $sib = $elem->sprev_sibling() or return;
        return if $sib ne ';';
        return $self->violation( $DESC, $EXPL, $elem );


}

1;

=head1 EXAMPLES

 $x = chomp $y;

 while (chomp $line = <STDIN>) {
 }

 split /,/, chomp <$fh>;

I think ; need to be before chomp

=cut

