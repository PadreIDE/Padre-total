package Padre::DB;

# Provide an ORLite-based API for the Padre database

use strict;
use Params::Util  ();
use Padre::Config ();
use ORLite 0.15 {
	file   => Padre::Config->default_db,
	create => 1,
	tables => 0,
};

our $VERSION = '0.16';

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
# History

sub add_history {
	my $class = shift;
	my $type  = shift;
	my $value = shift;
	$class->do(
		"insert into history ( type, name ) values ( ?, ? )",
		{}, $type, $value,
	);
	return;
}

sub get_history {
	my $class = shift;
	my $type  = shift;
	die "CODE INCOMPLETE";
}

sub get_recent {
	my $class  = shift;
	my $type   = shift;
	my $limit  = Params::Util::_POSINT(shift) || 10;
	my $recent = $class->selectcol_arrayref(
		"select distinct name from history where type = ? order by id desc limit $limit",
		{}, $type,
	) or die "Failed to find revent files";
	return wantarray ? @$recent : $recent;
}

sub delete_recent {
	my ( $class, $type ) = @_;
	
	$class->do(
		"DELETE FROM history WHERE type = ?",
		{}, $type
	);
	
	return 1;
}

sub get_last {
	my $class  = shift;
	my @recent = $class->get_recent(shift, 1);
	return $recent[0];
}

sub add_recent_files {
	$_[0]->add_history('files', $_[1]);
}

sub get_recent_files {
	$_[0]->get_recent('files');
}

sub add_recent_pod {
	$_[0]->add_history('pod', $_[1]);
}

sub get_recent_pod {
	$_[0]->get_recent('pod');
}

sub get_last_pod {
	$_[0]->get_last('pod');
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.