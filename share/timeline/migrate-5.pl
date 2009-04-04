use strict;
use File::Spec ();
use lib File::Spec->rel2abs(
	File::Spec->catdir(
		File::Spec->updir,
		File::Spec->updir,
		File::Spec->updir,
		File::Spec->updir,
		File::Spec->updir,
	)
);
use Padre::DB::Patch;





#####################################################################
# Patch Content

# create the session table
do(<<'END_SQL');
CREATE TABLE session (
	id INTEGER NOT NULL PRIMARY KEY,
	file VARCHAR(255) UNIQUE NOT NULL,
	line INTEGER NOT NULL,
	character INTEGER NOT NULL,
	clue VARCHAR(255),
	focus BOOLEAN NOT NULL
)
END_SQL

exit(0);
