package Padre::Plugin::SVN::Dialog::Commit;

use 5.008;
use strict;
use warnings;


# Version required
use version;
our $VERSION = qv(0.01);

use Padre::Wx;
use Padre::Plugin::SVN::FBP::Commit;
use Padre::Logger;

our @ISA = 'Padre::Plugin::SVN::FBP::Commit';


sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# my $main = shift;
	# my $info = shift;

	$self->CenterOnParent;

	# my $self = $class->SUPER::new($main);

	# $self->txtFilePath("Testing Path");

	return $self;
}


sub on_click_ok {
	my $self = shift;

	print "OK has been clicked\n";
	
	return;
}


1;
