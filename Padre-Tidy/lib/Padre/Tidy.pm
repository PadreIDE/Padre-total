package Padre::Tidy;

use 5.008;
use strict;
use warnings;
use PPI                   1.203 ();
use PPI::Document::File   1.203 ();
use File::Find::Rule       0.30 ();
use File::Find::Rule::VCS  1.06 ();
use File::Find::Rule::Perl 1.08 ();

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	unless ( 
}

sub root {
	$_[0]->{root};
}

sub run {
	my $class = shift;

	# Search for files
	my @files = File::Find::Rule->ignore_svn->perl_files->file->writeable;
	foreach my $file ( @files ) {
		print STDOUT "$file... ";

		# Parse the file
		my $document = PPI::Document::File->new($file);
		unless ( $document ) {
			print STDOUT "PARSE FAILED\n";
			next;
		}

		# Index locations
		$document->index_locations;

		# Apply the improved vertical align for use statements
		my $rv = Padre::Tiny::VerticalAlignUse->apply( $document );
		print $rv ? "CHANGED\n" : "unchanged\n";

		# Save changes
		$document->save if $rv;
	}

	return 1;
}

1;
