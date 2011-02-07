package Padre::Document::LaTeX::Syntax;

# ABSTRACT: Latex document syntax-checking in the background

use strict;
use warnings;

our @ISA = 'Padre::Task::Syntax';

sub new {
	my $class = shift;

	my %args = @_;

	my $self = $class->SUPER::new(%args);

	return $self;
}


sub syntax {
	my $self = shift;
	my $text = shift;

	my $filename    = $self->{filename};
	my $project_dir = $self->{project};

	my $pdflatex_command = "cd $project_dir; pdflatex -file-line-error -draftmode -interaction nonstopmode $filename";
	my $output           = `$pdflatex_command`;

	warn "Complete output: >>>$output<<<\n";

	my @lines = split /\n/, $output;
	my @issues = ();

	LINE:
	for ( my $i = 0; $i < scalar @lines; $i++ ) {
		my $line = $lines[$i];

		next LINE if not $line =~ /.*:(\d+):\s*(.*)/;
		my $line_no   = $1;
		my $error_msg = $2;

		warn "line: '$line'\n";

		while ( ++$i < scalar @lines && $lines[$i] !~ /^\[\d+\]/ ) {
			$lines[$i] =~ s/^l\.\d+ / /;
			$error_msg .= $lines[$i];
		}

		$error_msg =~ s/\s+/ /g;

		warn "$line_no: '$error_msg'\n";

		my %issue = (
			line    => $line_no,
			file    => $filename,
			type    => 'F',
			message => $error_msg,
		);

		push @issues, \%issue;
	}

	return \@issues;
}

1;

__END__

=pod

=head1 SYNOPSIS

Syntax checking for LaTeX documents

=head1 DESCRIPTION

This class implements syntax checking of LaTeX documents in
the background. It inherits from L<Padre::Task::Syntax>.
Please read its documentation!

=head1 SEE ALSO

This class inherits from L<Padre::Task::Syntax> which
in turn is a L<Padre::Task> and its instances can be scheduled
using L<Padre::TaskManager>.

=cut
