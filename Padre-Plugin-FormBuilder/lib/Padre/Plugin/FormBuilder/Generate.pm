package Padre::Plugin::FormBuilder::Generate;

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

sub dialog {
	$_[0]->{dialog};
}

sub padre {
	$_[0]->{padre};
}

sub package {
	$_[0]->{package};
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
		$self->{errstr} = "Missing or invalid FBP file";
		return 0;
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
		$self->{errstr} = "Failed to load FBP file '$file'";
		return 0;
	}

	# Capture the dialog list
	$self->{list} = [
		grep { defined $_ and length $_ }
		map  { $_->name }
		$xml->find( isa => 'FBP::Dialog' )
	];

	# Find the dialog
	my $fbp = $xml->find_first(
		isa  => 'FBP::Project',
	);
	my $dialog = $fbp->find_first(
		isa  => 'FBP::Dialog',
		name => $self->{dialog},
	);
	unless ( $dialog ) {
		return $self->error("Failed to find dialog $self->{dialog}");
	}

	# Generate (but just the default version)
	require FBP::Perl;
	$perl = FBP::Perl->new(
		project => $fbp,
	);

	# Generate the class code
	$self->{code} = $perl->flatten(
		$perl->dialog_class( $dialog, $self->package )
	);

	return 1;
}

1;
