package Padre::Plugin::PDL::Help;

use 5.008;
use strict;
use warnings;

# For Perl 6 documentation support
use Padre::Help ();

our $VERSION = '0.03';

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
		} else {
			if ( defined $topic ) {
				$line =~ s/^\s+//;
				$help->{$topic} .= " $line";
			}
		}
	}

	$self->{help} = $help;

	# Workaround to get Perl + PDL help
	require Padre::Document::Perl::Help;
	$self->{p5_help} = Padre::Document::Perl::Help->new;
	$self->{p5_help}->help_init;
}

#
# Renders the help topic content
#
sub help_render {
	my $self  = shift;
	my $topic = shift;

	my ( $html, $location );
	if ( exists $self->{help}->{$topic} ) {
		require Capture::Tiny;
		$html = Capture::Tiny::capture_stdout(
		    sub {
			require PDL::Doc::Perldl;
			PDL::Doc::Perldl::help($topic);

			return;
		    }
		);
		$html = "<pre>$html</pre>";
		$location = $topic;
	} else {
		( $html, $location ) = $self->{p5_help}->help_render($topic);
	}

	return ( $html, $location );
}

#
# Returns the help topic list
#
sub help_list {
	my $self = shift;

	# Return a unique sorted index
	my @index = keys $self->{help};

	# Add Perl 5 help index to PDL
	foreach my $topic ( @{ $self->{p5_help}->help_list } ) {
		push @index, $topic;
	}

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
