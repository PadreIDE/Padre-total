package Padre::Plugin::SVN::Dialog::Commit;

use 5.008;
use strict;
use warnings;


# Version required
use version; 
our $VERSION = qv(0.01);

use parent qw( Padre::Plugin::SVN::FBP::Commit );


sub new {
	my $class = shift;
	my $main = shift;
	my $info = shift;
	
	my $self = $class->SUPER::new($main);

	 $self->txtFilePath("Testing Path");
	
	return $self;
}


sub on_click_ok {
		my $self = shift;
		 print "OK has been clicked\n";
}

sub on_click_cancel {
		my $self = shift;
		 print "Cancel has been clicked\n";
		 
}






1;