package Padre::Plugin::YAML::Syntax;

use 5.010001;
use strict;
use warnings;

use Padre::Task::Syntax ();
use Padre::Wx           ();
use Try::Tiny;


our $VERSION = '0.04';
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

	say "text to check follows:\n$text\nend's here:";

	my $error;

	try {
		require YAML::XS;
		YAML::XS::Load($text);
	}
	catch {
		say "Info: from YAML::XS::Load: $_";
		return $self->_parse_error($_);
	}
	finally {

		# No errors...
		# return $self->_parse_error('YAML good: to go');

		# Short circuit if the syntax is OK and no other errors/warnings are present
		# return [] if $stderr eq "- syntax OK\n";

		# return 	$tree->SetItemText(
		# $root,
		# sprintf( Wx::gettext('No errors or warnings found in %s within %3.2f secs.'), $filename, $elapsed )
		# );

		# return 	$tree->SetItemText(
		# $root,
		# Wx::gettext('No errors or warnings found within.'),
		# );

		# return [];
		# my @issues = ();
		# push @issues, {
		# message => Wx::gettext('No errors or warnings found within.'),

		# # line => $line,
		# type => 'W',

		# file => $self->{filename},
		# };

		# return { issues => \@issues, };

		return [];

	};
}

sub _parse_error {
	my $self  = shift;
	my $error = shift;

	say "error = $error";

	my @issues = ();
	my ( $type, $message, $code, $line, $column ) = (
		'Error',
		Wx::gettext('Unknown YAML error'),
		undef,
		1
	);
	for ( split '\n', $error ) {
		if (/YAML::XS::Load (\w+)\: .+/) {
			$type = $1;
		} elsif (/^\s+(found.+)/) {
			$message = $1;
		} elsif (/^\s+Code: (.+)/) {
			$code = $1;
		} elsif (/line:\s(\d+), column:\s(\d+)/) {
			$line   = $1;
			$column = $2;
		}
	}
	say "type = $type";
	say "message = $message";

	# say "code = $code";
	say "line = $line";
	say "column = $column";

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

This document describes Padre::Plugin::YAML::Syntax version 0.04


=head1 DESCRIPTION

This class implements syntax checking of YAML documents in
the background. It inherits from L<Padre::Task::Syntax>.
Please read its documentation.


=head1 BUGS AND LIMITATIONS

Now using YAML::XS

    supports %TAG = %YAML 1.1 or no %TAG 


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
