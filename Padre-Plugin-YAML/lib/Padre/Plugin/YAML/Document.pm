package Padre::Plugin::YAML::Document;

use v5.10.1;
use strict;
use warnings;

use Padre::Document ();

our $VERSION = '0.08';
use parent qw(Padre::Document);


sub task_functions {
	return '';
}

sub task_outline {
	return '';
}

sub task_syntax {
	return 'Padre::Plugin::YAML::Syntax';
}

sub comment_lines_str {
	return '#';
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::YAML::Document - YAML support for Padre The Perl IDE


=head1 VERSION

version: 0.08


=head1 DESCRIPTION

YAML support for Padre, the Perl Application Development and Refactoring
Environment.

	# Called by padre to know which document to register for this plugin
	sub registered_documents {
		return (
			'text/x-yaml' => 'Padre::Plugin::YAML::Document',
		);
	}

Syntax highlighting for YAML is supported by Padre out of the box.
This plug-in adds some more features to deal with YAML files.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.


=head1 METHODS

=over 4

=item * comment_lines_str

=item * task_functions

=item * task_outline

=item * task_syntax

=back


=head1 AUTHOR

Zeno Gantner E<lt>zenog@cpan.orgE<gt>

=head1 CONTRIBUTORS

Kevin Dawson  E<lt>bowtie@cpan.orgE<gt>

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011-2013, Zeno Gantner E<lt>zenog@cpan.orgE<gt>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
