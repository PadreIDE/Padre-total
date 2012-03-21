package Padre::Plugin::YAML::Syntax;

use v5.10;
use strict;
use warnings;

use Padre::Logger;
use Padre::Task::Syntax ();
use Padre::Wx           ();

our $VERSION = '0.05';
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

	TRACE("\n$text") if DEBUG;

	eval {
		if ( $^O =~ /Win32/i )
		{
			require YAML;
			YAML::Load($text);
		} else {
			require YAML::XS;
			YAML::XS::Load($text);
		}
	};
	if ($@) {
		TRACE("\nInfo: from YAML::XS::Load: $@") if DEBUG;
		return $self->_parse_error($@);
	}

	# No errors...
	return {};

}

sub _parse_error {
	my $self  = shift;
	my $error = shift;

	my @issues = ();
	my ( $type, $message, $code, $line, $column ) = (
		'Error',
		Wx::gettext('Unknown YAML error'),
		undef,
		1
	);

	# from the following in scanner.c inside YAML::XS
	foreach ( split '\n', $error ) {
		when (/YAML::XS::Load (\w+)\: .+/) {
			$type = $1;
		}
		when (/^\s+(found.+)/) {
			$message = $1;
		}
		when (/^\s+(could not.+)/) {
			$message = $1;
		}
		when (/^\s+(did not.+)/) {
			$message = $1;
		}
		when (/^\s+(block.+)/) {
			$message = $1;
		}
		when (/^\s+(mapping.+)/) {
			$message = $1;
		}
		when (/^\s+Code: (.+)/) {
			$code = $1;
		}
		when (/line:\s(\d+), column:\s(\d+)/) {
			$line   = $1;
			$column = $2;
		}
	}

	if (DEBUG) {
		say "type = $type"       if $type;
		say "message = $message" if $message;
		say "code = $code"       if $code;
		say "line = $line"       if $line;
		say "column = $column"   if $column;
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
	};

}


1;

__END__


=pod

=head1 NAME

Padre::Plugin::YAML::Syntax - YAML document syntax-checking in the background


=head1 VERSION

This document describes Padre::Plugin::YAML::Syntax version 0.05


=head1 DESCRIPTION

This class implements syntax checking of YAML documents in
the background. It inherits from L<Padre::Task::Syntax>.
Please read its documentation.


=head1 BUGS AND LIMITATIONS

Now using YAML::XS

    supports %TAG = %YAML 1.1 or no %TAG 

If you receive "Unknown YAML error" please inform dev's with sample code that causes this, Thanks.

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
