package Padre::Plugin::PDL::Help;

use 5.008;
use strict;
use warnings;

# For Perl 6 documentation support
use Padre::Help ();

our $VERSION = '0.02';

our @ISA = 'Padre::Help';

#
# Initialize help
#
sub help_init {
	my $self = shift;
	
	require Capture::Tiny;
	my $help_list_output = Capture::Tiny::capture_stdout(
	    sub {
		require PDL::Doc::Perldl;
		PDL::Doc::Perldl::apropos('.*');
		return;
	    }
	);

	my $help = ();
	my $topic;
	for my $line ( split /\n/, $help_list_output ) {
	    if ( $line =~ /^(\S+)\s+(.+)$/ ) {
		$topic = $1;
		$help->{$topic} = $2;
	    }
	    else {
		if ( defined $topic ) {
		    $line =~ s/^\s+//;
		    $help->{$topic} .= " $line";
		}
	    }
	}
	
	$self->{help} = $help;
}

#
# Renders the help topic content
#
sub help_render {
	my ( $self, $topic ) = @_;

	my $html = $self->{help}->{$topic};
	return ( $html, $topic );
}

#
# Returns the help topic list
#
sub help_list {
	my ($self) = @_;

	# Return a unique sorted index
	my @index = keys $self->{help};
	my %seen = ();
	my @unique_sorted_index = sort grep { !$seen{$_}++ } @index;
	return \@unique_sorted_index;
}

1;

__END__

=head1 NAME

Padre::Plugin::PDL::Help - PDL help provider for Padre

=head1 DESCRIPTION

PDL Help index is built here and rendered.
