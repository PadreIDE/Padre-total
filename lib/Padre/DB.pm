package Padre::DB;

# Provide an ORLite-based API for the Padre database

use strict;
use Padre::Config ();
use ORLite 0.15 {
	file   => Padre::Config->default_db,
	create => 1,
	tables => 0,
};

our $VERSION = '0.10';

# At load time, autocrate if needed
unless ( Padre::DB->pragma('user_version') == 2 ) {
	Padre::DB->setup;
}






#####################################################################
# General Methods

sub table_exists {
	$_[0]->selectrow_array(
		"select count(*) from sqlite_master where type = 'table' and name = ?",
		{}, $_[1],
	);
}

sub setup {
	my $class = shift;

	# Create the host settings table
	$class->do(<<'END_SQL') unless $class->table_exists('hostconf');
CREATE TABLE hostconf (
	name VARCHAR(255) PRIMARY KEY,
	value VARCHAR(255)
)
END_SQL

	# Create the modules table
	$class->do(<<'END_SQL') unless $class->table_exists('modules');
CREATE TABLE modules (
	id INTEGER PRIMARY KEY,
	name VARCHAR(255)
)
END_SQL

	# Create the history table
	$class->do(<<'END_SQL') unless $class->table_exists('history');
CREATE TABLE history (
	id INTEGER PRIMARY KEY,
	type VARCHAR(255),
	name VARCHAR(255)
)
END_SQL

	$class->pragma('user_version', 1);
}





#####################################################################
# Host Preference Methods

sub hostconf_read {
	my $class = shift;
	my $rows  = $class->selectall_arrayref('select name, value from hostconf');
	return { map { @$_ } @$rows };
}

sub hostconf_write {
	my $class = shift;
	my $hash  = shift;
	$class->begin;
	$class->do('delete from hostconf');
	foreach my $key ( sort keys %$hash ) {
		$class->do(
			'insert into hostconf ( name, value ) values ( ?, ? )',
			{}, $key => $hash->{$key},
		);
	}
	$class->commit;
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
