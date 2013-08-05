package Parse::ErrorString::Perl::ErrorItem;

#ABSTRACT: a Perl error item object

use strict;
use warnings;

our $VERSION = '0.17';

use Class::XSAccessor getters => {
	type             => 'type',
	type_description => 'type_description',
	message          => 'message',
	file             => 'file',
	file_abspath     => 'file_abspath',
	file_msgpath     => 'file_msgpath',
	line             => 'line',
	near             => 'near',
	diagnostics      => 'diagnostics',
	at               => 'at',
};

sub new {
	my ( $class, $self ) = @_;
	bless $self, ref $class || $class;
	return $self;
}

sub stack {
	my $self = shift;
	return $self->{stack} ? @{ $self->{stack} } : undef;

}

1;

__END__

=head1 Parse::ErrorString::Perl::ErrorItem

Each object contains the following accessors (only C<message>, C<file>,
and C<line> are guaranteed to be present for every error):

=over

=item type

Normally returns a single letter identifying the type of the error. The
possbile options are C<W>, C<D>, C<S>, C<F>, C<P>, C<X>, and C<A>.
Sometimes an error can be of either of two types, in which case a string
such as "C<S|F>" is returned in scalar context and a list of the two
letters is returned in list context. If C<type> is empty, you can assume
that the error was not emitted by perl itself, but by the user or by a
third-party module.

=item type_description

A description of the error type. The possible options are:

    W => warning
    D => deprecation
    S => severe warning
    F => fatal error
    P => internal error
    X => very fatal error
    A => alien error message

If the error can be of either or two types, the two types are
concactenated with "C< or >". Note that this description is always
returned in English, regardless of the C<lang> option.

=item message

The error message.

=item file

The path to the file in which the error occurred, possibly truncated. If
the error occurred in a script, the parser will attempt to return only
the filename; if the error occurred in a module, the parser will attempt
to return the path to the module relative to the directory in @INC in
which it resides.

=item file_abspath

Absolute path to the file in which the error occurred.

=item file_msgpath

The file path as displayed in which the error message.

=item line

Line in which the error occurred.

=item near

Text near which the error occurred (note that this often contains
newline characters).

=item at

Additional information about where the error occurred (e.g. "C<at EOF>").

=item diagnostics

Detailed explanation of the error (from L<perldiag>). If the C<lang>
option is specified when constructing the parser, an attempt will be
made to return the diagnostics message in the appropriate language. If
an explanation is not found in the localized perldiag, the default
perldiag will also be searched. Returned as raw pod, so you may need to
use a pod parser to render into the format you need.

=item stack

Callstack for the error. Returns a list of Parse::ErrorString::Perl::StackItem objects.

=back
