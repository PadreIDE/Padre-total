package Padre::Document::LaTeX::Syntax;

# ABSTRACT: Latex document syntax-checking in the background

use strict;
use warnings;
use Padre::Task::Syntax ();

our @ISA = 'Padre::Task::Syntax';

sub new {
	my $class = shift;

	my %args = @_;
	my $self = $class->SUPER::new(%args);

	return $self;
}

sub _call_pdflatex {
	my ( $self, $text ) = @_;

	my $project_dir = $self->{project};

	# create temporary directory and LaTeX file
	require File::Temp;
	my $tempdir = File::Temp::tempdir( 'Padre-Document-LaTeX-Syntax-XXXXXX', TMPDIR => 1 );
	my $file = File::Temp->new(
		TEMPLATE => 'XXXXXX',
		UNLINK   => 1, DIR => $project_dir
	);

	# write text to temporary file
	my $filename = $file->filename;
	binmode( $file, ':utf8' );
	$file->print($text);
	$file->close;

	# run pdflatex
	my $pdflatex_command =
		"cd $project_dir; pdflatex -file-line-error -draftmode -interaction nonstopmode -output-directory $tempdir $filename";

	#warn "$pdflatex_command\n";
	my $output = `$pdflatex_command`;

	eval {

		# clean up
		require File::Path;
		File::Path::remove_tree($tempdir);
	};
	warn "$@\n" if $@;

	return $output;
}


sub syntax {
	my $self = shift;
	my $text = shift;

	my $output = $self->_call_pdflatex($text);

	#warn "OUTPUT: $output\n";

	my @lines = split /\n/, $output;
	my @issues = ();

	LINE:
	for ( my $i = 0; $i < scalar @lines; $i++ ) {
		my $line = $lines[$i];

		next LINE if not $line =~ /.*:(\d+):\s*(.*)/;
		my $line_no   = $1;
		my $error_msg = $2;

		while ( ++$i < scalar @lines && $lines[$i] !~ /^\s*$/ && $lines[$i] !~ /<recently read>/ ) {
			$lines[$i] =~ s/^l\.\d+ / /;
			$error_msg .= $lines[$i];
		}

		$error_msg =~ s/\s+/ /g;

		#warn "error msg '$error_msg'\n";

		my %issue = (
			line    => $line_no,
			file    => $self->{filename},
			type    => 'F',
			message => $error_msg,
		);

		push @issues, \%issue;
	}
	my $num_issues = scalar @issues;

	#warn "pdflatex output parsing: found $num_issues issues.\n";

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
