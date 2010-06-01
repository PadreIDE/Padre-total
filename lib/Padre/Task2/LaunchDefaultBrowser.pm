package Padre::Task2::LaunchDefaultBrowser;

# The Wx::LaunchDefaultBrowser function blocks until the default
# browser has been launched. For something like a heavily loaded down
# Firefox, this can take perhaps a minute.
# This task moves the function into the background.

use 5.008;
use strict;
use warnings;
use Padre::Task2 ();

# We don't need to load all of Padre::Wx for this
use Wx (); 

our $VERSION = '0.59';
our @ISA     = 'Padre::Task2';

sub run {
	Wx::LaunchDefaultBrowser( $_[0]->{url} );
	return 1;
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
