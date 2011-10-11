package Padre::Plugin::Debug::Bottom;

use 5.008;
use strict;
use warnings;


use Padre::Wx::Role::View ();
use Padre::Plugin::Debug::FBP::DebugPL;

our $VERSION = '0.01';
our @ISA     = qw{ Padre::Wx::Role::View Padre::Plugin::Debug::FBP::DebugPL };


#######
# new
#######
sub new {
    my $class = shift;
	my $main  = shift;
	my $panel = $main->bottom;

    # Create the panel
    my $self  = $class->SUPER::new($panel);
    
    $main->aui->Update;

    return $self;
}

sub view_label {
	return 'bottom';
}

1;

__END__

