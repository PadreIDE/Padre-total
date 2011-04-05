package Padre::Plugin::FormBuilder::List;

use 5.008005;
use strict;
use warnings;
use Padre::Task ();

our $VERSION  = '0.85';
our @ISA      = 'Padre::Task';





######################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(@_);

	# Initialise
	$self->{list}   = '';
	$self->{errstr} = '';

	return $self;
}

sub file {
	$_[0]->{file};
}

sub list {
	$_[0]->{list};
}

sub errstr {
	$_[0]->{errstr};
}





######################################################################
# Padre::Task Methods

sub prepare {
	my $self = shift;

	# Does the input file exist
	unless ( $self->{file} and -f $self->{file} ) {
		return $self->error("Missing or invalid FBP file");
	}

	return 1;
}

sub run {
	my $self = shift;
	my $file = $self->file;

	# Load the file
	require FBP;
	my $xml = FBP->new;
	my $ok  = $xml->parse_file($file);
	unless ( $ok ) {
		return $self->error("Failed to load FBP file '$file'");
	}

	# Capture the dialog list
	$self->{list} = [
		grep { defined $_ and length $_ }
		map  { $_->name }
		$xml->find( isa => 'FBP::Dialog' )
	];

	return 1;
}





######################################################################
# Support Methods

sub error {
	$_[0]->{errstr} = $_[1];
	return 0;
}

1;
