package Padre::Plugin::PDL::Help;

use 5.008;
use strict;
use warnings;

# For Perl 6 documentation support
use Padre::Help ();

our $VERSION = '0.04';

our @ISA = 'Padre::Help';

#
# Initialize help
#
sub help_init {
	my $self = shift;

	eval {
		require PDL::Doc;

		# Find the pdl documentation
		my $pdldoc;
		DIRECTORY: for my $dir (@INC) {
			my $file = "$dir/PDL/pdldoc.db";
			if ( -f $file ) {
				$pdldoc = new PDL::Doc($file);
				last DIRECTORY;
			}
		}

		if ( defined $pdldoc ) {
			$self->{pdl_help} = $pdldoc->gethash;
		}
	};
	if ($@) {
		warn "Failed to load PDL docs: $@";
	}

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
	my $pdl_help = $self->{pdl_help};
	if ( defined $pdl_help && exists $pdl_help->{$topic} ) {
		$html = '';
		my $help         = $pdl_help->{$topic};
		my %SECTION_NAME = (
			Module  => 'Module',
			File    => 'File',
			Ref     => 'Reference',
			Sig     => 'Signature',
			Bad     => 'Bad values',
			Usage   => 'Usage',
			Example => 'Example',
		);
		foreach my $section (qw(Module File Ref Sig Bad Usage Example)) {
			if ( defined $help->{$section} ) {
				my $help = $help->{$section};
				my $name = $SECTION_NAME{$section};
				if (   $section eq 'Example'
					or $section eq 'Sig'
					or $section eq 'Usage' )
				{
					$html .= "<p><b>$name</b><pre>" . $help . "</pre></p>";
				} else {
					$html .= "<p><b>$name</b><br>" . $help . "</p>";
				}
			}
		}

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
	my @index = keys %{ $self->{pdl_help} };

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
