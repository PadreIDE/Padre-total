package Padre::Plugin::wxGlade::WXG;

use strict;
use warnings;
use Params::Util qw{ _STRING _HASH };
# use XML::Tiny ();

our $VERSION = '0.01';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $file  = shift;

	# Parse the XML file
	require XML::Tiny;
	my $document = XML::Tiny::parsefile( $file );

	# Validate the file
	unless ( _HASH($document->[0]) and $document->[0]->{name} eq 'application' ) {
		die("Invalid or unsupported wxGlade XML");
	}

	# Create the WXG object
	my $self = $document->[0];
	bless $self, $class;

	# Save the path to the wxg file
	$self->{wxg} = $file;

	return $self;
}

sub wxg {
	$_[0]->{wxg};
}

sub language {
	$_[0]->{attrib}->{language};
}

sub for_version {
	$_[0]->{attrib}->{for_version};
}

sub path {
	$_[0]->{attrib}->{path};
}

# Smarter equivalent for path
sub file {
	my $self = shift;

	# Handle null cases
	unless ( defined _STRING($self->path) ) {
		return $self->path;
	}

	# Handle the trivial positive case
	if ( -f $self->path ) {
		return $self->path;
	}

	# Because wxGlade saves absolute paths, they don't transport well.
	# If the literal path doesn't exist, add support for the generated
	# file being in the same directory as the WXG file itself.
	die( "CODE INCOMPLETE" );
}

# Valid usable top level objects
sub objects {
	grep {
		$_->{type} eq 'e'
		and
		$_->{name} eq 'object'
		and
		$_->{attrib}->{name}
		and
		$_->{attrib}->{class}
	} @{$_[0]->{content}};
}

# The list of top level window names in the application
sub windows {
	grep {
		defined _STRING($_)
	} map {
		$_->{attrib}->{name}
	} $_[0]->objects
}

# Fetch a window tag
sub window {
	my $self = shift;
	my $name = shift;
	foreach ( $self->objects ) {
		next unless $_->{attrib}->{name} eq $name;
		return $_;
	}
	return;
}

# Fetch the top window
sub top_window {
	my $self = shift;
	$self->window( $self->{attrib}->{top_window} );
}





######################################################################
# Main Methods

sub supported {
	my $self = shift;
	unless ( $self->language and $self->language eq 'perl' ) {
		die("The wxGlade application is not targetting Perl");
	}
	unless ( $self->for_version and $self->for_version eq '2.8' ) {
		die("The wxGlade application is not build for wxGlade 2.8");
	}
	my $path = $self->path;
	unless ( $path and -f $path ) {
		die("The wxGlade output path '$path' does not exist");
	}
	return 1;
}

# Loads the Perl code for a single named window
sub extract {
	my $self    = shift;
	my $window  = shift;

	# Load the Perl file and localize newlines
	my $file = $self->file;
	my $perl = _lslurp($file);

	# Extract the class from the overall file
	my $package = $window->{attrib}->{class};
	my @code    = $$perl =~ /\n(package $package;.+?# end of class $package\n+1;\n)/sg;
	unless ( @code ) {
		die("Failed to find package '$package' in file '$file'");
	}
	unless ( @code == 1 ) {
		die("Found more than one package '$package' in file '$file'");
	}

	return $code[0];
}

# Provide a simple _slurp implementation (copied from PPI::Util)
# Avoids a 1 meg File::Slurp load.
sub _lslurp {
	my $file = shift;
	local $/ = undef;
	local *FILE;
	open( FILE, '<', $file ) or die("open($file) failed: $!");
	my $source = <FILE>;
	close( FILE ) or die("close($file) failed: $!");
	$source =~ s/(?:\015{1,2}\012|\015|\012)/\n/sg;
	return \$source;
}

1;
