package Parse::ErrorString::Perl::StackItem;

#ABSTRACT: a Perl stack item object

use strict;
use warnings;

our $VERSION = '0.19';

sub new {
	my ( $class, $self ) = @_;
	bless $self, ref $class || $class;
	return $self;
}

use Class::XSAccessor getters => {
	sub          => 'sub',
	file         => 'file',
	file_abspath => 'file_abspath',
	file_msgpath => 'file_msgpath',
	line         => 'line',
};

1;

__END__

=head1 Parse::ErrorString::Perl::StackItem

=over

=item sub

The subroutine that was called, qualified with a package name (as
printed by C<use diagnostics>).

=item file

File where subroutine was called. See C<file> in
C<Parse::ErrorString::Perl::ErrorItem>.

=item file_abspath

See C<file_abspath> in C<Parse::ErrorString::Perl::ErrorItem>.

=item file_msgpath

See C<file_msgpath> in C<Parse::ErrorString::Perl::ErrorItem>.

=item line

The line where the subroutine was called.

=back
