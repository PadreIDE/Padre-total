package Padre::DB;

# Provide an ORLite-based API for the Padre database

use strict;
use Padre::Config ();
use ORLite 0.14 {
	file   => Padre::Config->default_db,
	create => 1,
	tables => 0,
};

our $VERSION = '0.10';

# At load time, autocrate if needed
unless ( Padre::DB->pragma('user_version') ) {
	Padre::DB->create;
}






#####################################################################
# General Methods

sub create {
	my $class = shift;

	# Create the modules table
	$class->do(<<'END_SQL');
CREATE TABLE modules (
	id INTEGER PRIMARY KEY,
	name VARCHAR(100)
)
END_SQL

	# Create the history table
	$class->do(<<'END_SQL');
CREATE TABLE history (
	id INTEGER PRIMARY KEY,
	type VARCHAR(100),
	name VARCHAR(100)
)
END_SQL

	# Set the schema version
	$class->pragma('user_version', 1);

	return 1;
}





#####################################################################
# Modules Methods

sub add_modules {
	my $class = shift;
	foreach my $module ( @_ ) {
		$class->do(
			"INSERT INTO modules ( name ) VALUES ( ? )",
			{}, $module,
		);
	}
	return;
}

sub delete_modules {
	shift->do("DELETE FROM modules");
}

sub find_modules {
	my $class = shift;
	my $part  = shift;
	my $sql   = "SELECT name FROM modules";
	my @bind_values;
	if ( $part ) {
		$sql .= " WHERE name LIKE ?";
		push @bind_values, '%' . $part .  '%';
	}
	$sql .= " ORDER BY name";
	return $class->selectcol_arrayref($sql, {}, @bind_values);
}





#####################################################################
# Recent Files

sub add_recent_files {
	my $class = shift;
	my $file  = shift;
	$class->do(
		"INSERT INTO history ( type, name ) VALUES ( 'files', ? )",
		{}, $file,
	);
	return;
}

sub get_recent_files {
	my $files = shift->selectcol_arrayref(
		"SELECT DISTINCT name FROM history where type = 'file' ORDER BY id",
	) or die "Failed to find revent files";
	return @$files;
}





#####################################################################
# Recent POD Methods

sub add_recent_pod {
	my $class = shift;
	my $file  = shift;
	$class->do(
		"INSERT INTO history ( type, name ) VALUES ( 'pod', ? )",
		{}, $file,
	);
	return;
}

sub get_recent_pod {
	my $pod = shift->selectcol_arrayref(
		"SELECT DISTINCT name FROM history where type = 'pod' ORDER BY id",
	) or die "Failed to find revent pod";
	return @$pod;
}

sub get_current_pod {
	return ($_[0]->get_recent_pod)[-1];
}

1;
