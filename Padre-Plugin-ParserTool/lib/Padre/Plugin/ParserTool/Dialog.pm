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
		if ( $@ ) {
			return $self->error("Failed to load '$module': $@");
		}
	}

	# 
	
}

1;
