package Padre::Swarm::Message::Diff;

use strict;
use warnings;
use Padre::Swarm::Message ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Swarm::Message';

use Class::XSAccessor
	constructor => 'new',
	accessors   => {
		file        => 'file',
		project     => 'project',
		project_dir => 'project_dir',
		diff        => 'diff',
		comment     => 'comment',
	};

1;
