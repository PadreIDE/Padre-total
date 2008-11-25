package Padre::Project;

# Base project functionality for Padre

use strict;
use warnings;
use File::Spec ();
use YAML::Tiny ();

our $VERSION = '0.18';





######################################################################
# Constructor and Accessors

sub new {

}

sub root {
	$_[0]->{root}
}

sub padre_yml {
	$_[0]->{padre_yml}
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
