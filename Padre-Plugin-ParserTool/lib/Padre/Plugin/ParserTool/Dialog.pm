package Padre::Plugin::ParserTool::Dialog;

use 5.008;
use strict;
use warnings;
use Params::Util                   ();
use Padre::Wx::Role::Dialog        ();
use Padre::Plugin::ParserTool::FBP ();

our $VERSION = '0.01';
our @ISA     = qw{
	Padre::Wx::Role::Dialog
	Padre::Plugin::ParserTool::FBP
};





######################################################################
# Padre::Plugin::ParserTool::FPB Methods

sub refresh {
	my $self = shift;

	# Check the module
	my $module = $self->{module}->GetValue;
	unless ( Params::Util::_CLASS($module) ) {
		return $self->error("Missing or invalid module '$module'");
	}

	# Load the module
	SCOPE: {
		local $@;
		eval "require $module";
		return $self->error("Failed to load '$module': $@") if $@;
	}

	# Call the code
	local $@;
	my $code = $self->{function}->GetValue;
	my $rv   = do {
		local $_ = $self->{input}->GetValue;
		eval $code;
	};
	return $self->error("Failed to execute '$code': $@") if $@;

	# Serialize the output
	my $dumper = $self->{dumper}->GetStringSelection;
	if ( $dumper eq 'Stringify' ) {
		my $output = defined $rv ? "$rv" : 'undef';
		$self->{output}->SetValue($output);

	}elsif ( $dumper eq 'Data::Dumper' ) {
		require Data::Dumper;
		my $output = Data::Dumper::Dumper($rv);
		$self->{output}->SetValue($output);

	} elsif ( $dumper eq 'Devel::Dumpvar' ) {
		require Devel::Dumpvar;
		my $output = Devel::Dumpvar->new( to => 'return' )->dump($rv);
		$self->{output}->SetValue($output);

	} elsif ( $dumper eq 'PPI::Dumper' ) {
		unless ( Params::Util::_INSTANCE($rv, 'PPI::Element') ) {
			return $self->error("Not a PPI::Element object");
		}
		require PPI::Dumper;
		my $output = PPI::Dumper->new($rv)->string;
		$self->{output}->SetValue($output);

	} else {
		$self->error("Unknown or unsupported dumper '$dumper'");
	}
}

1;
