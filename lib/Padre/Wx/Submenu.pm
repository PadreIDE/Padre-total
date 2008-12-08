package Padre::Wx::Submenu;

use strict;
use Class::Adapter::Builder
	ISA      => 'Wx::Menu',
	NEW      => 'Wx::Menu',
	AUTOLOAD => 'PUBLIC';

our $VERSION = '0.20';

sub VERSION { $VERSION }

1;
