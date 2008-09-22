package Padre::DB;

# Provide an ORLite-based API for the Padre database

use strict;
use Padre;
use ORLite 0.13 {
	file   => Padre->ide->config_db,
	tables => 0,
};

our $VERSION = '0.10';

1;
