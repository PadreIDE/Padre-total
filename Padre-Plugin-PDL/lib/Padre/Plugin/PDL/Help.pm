package Padre::Plugin::PDL::Help;

use 5.008;
use strict;
use warnings;

# For Perl 6 documentation support
use Padre::Help ();

our $VERSION = '0.05';

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
			# Store in self for later access:
			$self->{pdl_help} = $pdldoc;
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
	if ( defined $pdl_help && exists $pdl_help->gethash->{$topic} ) {
		require Padre::Pod2HTML;
		
		# We have two possibilities: the $topic can either be a module, or it
		# can be a function. If the latter, we extract its pod from the database.
		# If the former, just pull the pod from the file. We distinguish between
		# them by noting that functions have a Module key, whereas modules 
		# (ironically) don't.
		if (exists $pdl_help->gethash->{$topic}->{Module}) {
			# Get the pod docs from the docs database:
			my $pod_handler = StrHandle->new; # defined in PDL::Doc
			$pdl_help->funcdocs($topic, $pod_handler);
			
			# Convert them to HTML
			$html = Padre::Pod2HTML->pod2html($pod_handler->text);
			
			# Replace the filename in the "docs from" section with the module name:
			my $module_name = $pdl_help->gethash->{$topic}{Module};
			$html =~ s{Docs from .*\.pm}
				{Docs from <a href="perldoc:$module_name">$module_name<\/a>};
		}
		else {
			$html = Padre::Pod2HTML->file2html($pdl_help->gethash->{$topic}->{File});
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
	my @index = keys %{ $self->{pdl_help}->gethash };

	# Add Perl 5 help index to PDL
	#foreach my $topic ( @{ $self->{p5_help}->help_list } ) {
	#	push @index, $topic;
	#}
	# I think this is a faster way of doing the above:
	push @index, @{ $self->{p5_help}->help_list };

	# Make sure things are only listed once:
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
