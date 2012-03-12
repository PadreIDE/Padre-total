package Padre::Plugin::YAML::Syntax;

use 5.010001;
use strict;
use warnings;

use Padre::Task::Syntax ();
use Padre::Wx           ();

our $VERSION = '0.02';
use parent qw(Padre::Task::Syntax);

sub new {
	my $class = shift;
	$class->SUPER::new(@_);
}

sub run {
	my $self = shift;

	# Pull the text off the task so we won't need to serialize
	# it back up to the parent Wx thread at the end of the task.
	my $text = delete $self->{text};

	# Get the syntax model object
	$self->{model} = $self->syntax($text);

	return 1;
}

sub syntax {
	my $self = shift;
	my $text = shift;

	my $error;
	eval {
		require YAML;
		YAML::Load($text);
	};
	if ($@) {
		return $self->_parse_error($@);
	} else {

		# No errors...
		return [];
	}
}

sub _parse_error {
	my $self  = shift;
	my $error = shift;

	my @issues = ();
	my ( $type, $message, $code, $line ) = (
		'Error',
		Wx::gettext('Unknown YAML error'),
		undef,
		1
	);
	for ( split '\n', $error ) {
		if (/YAML (\w+)\: (.+)/) {
			$type    = $1;
			$message = $2;
		} elsif (/^\s+Code: (.+)/) {
			$code = $1;
		} elsif (/^\s+Line: (.+)/) {
			$line = $1;
		}
	}
	push @issues,
		{
		message => $message . ( defined $code ? " ( $code )" : q{} ),
		line => $line,
		type => $type eq 'Error' ? 'F' : 'W',
		file => $self->{filename},
		};

	return {
		issues => \@issues,
		stderr => $error,
		}

}


1;

__END__


=pod

=head1 NAME

Padre::Plugin::YAML::Syntax - YAML document syntax-checking in the background


=head1 VERSION

This document describes Padre::Plugin::YAML::Syntax version 0.02


=head1 DESCRIPTION

This class implements syntax checking of YAML documents in
the background. It inherits from L<Padre::Task::Syntax>.
Please read its documentation.


=head1 DEPENDENCIES

None.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.


=head1 METHODS

=over 3

=item * new

=item * run

=item * syntax

=back


=head1 AUTHOR

Zeno Gantner E<lt>zenog@cpan.orgE<gt>

=head1 CONTRIBUTORS

Kevin Dawson  E<lt>bowtie@cpan.orgE<gt>

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011-2012, Zeno Gantner E<lt>zenog@cpan.orgE<gt>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
