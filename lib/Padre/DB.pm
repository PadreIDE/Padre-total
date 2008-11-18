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

our $VERSION = '0.17';

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

	# Create the snippets table
    unless ($class->table_exists('snippets')) {
        $class->do(<<'END_SQL');
CREATE TABLE snippets (
	id INTEGER PRIMARY KEY,
	category VARCHAR(255),
	name VARCHAR(255), 
	snippet TEXT
);
END_SQL
        my @prepsnips = (
            ['Char class', '[:&alnum:]','[:alnum:]'],
            ['Char class', '[:alp&ha:]','[:alpha:]'],
            ['Char class', '[:asc&ii:]','[:ascii:]'],
            ['Char class', '[:&blank:]','[:blank:]'],
            ['Char class', '[:&cntrl:]','[:cntrl:]'],
            ['Char class', '[:&digit:]','[:digit:]'],
            ['Char class', '[:&graph:]','[:graph:]'],
            ['Char class', '[:&lower:]','[:lower:]'],
            ['Char class', '[:&print:]','[:print:]'],
            ['Char class', '[:pu&nct:]','[:punct:]'],
            ['Char class', '[:&space:]','[:space:]'],
            ['Char class', '[:&upper:]','[:upper:]'],
            ['Char class', '[:&word:]','[:word:]'],
            ['Char class', '[:&xdigit:]','[:xdigit:]'],
            ['File test', 'age since inode change', '-C'],
            ['File test', 'age since last access', '-A'],
            ['File test', 'age since modification', '-M'],
            ['File test', 'binary file', '-B'],
            ['File test', 'block special file', '-b'],
            ['File test', 'character special file', '-c'],
            ['File test', 'directory', '-d'],
            ['File test', 'executable by eff. UID/GID', '-x'],
            ['File test', 'executable by real UID/GID', '-X'],
            ['File test', 'exists', '-e'],
            ['File test', 'handle opened to a tty', '-t'],
            ['File test', 'named pipe', '-p'],
            ['File test', 'nonzero size', '-s'],
            ['File test', 'owned by eff. UID', '-o'],
            ['File test', 'owned by real UID', '-O'],
            ['File test', 'plain file', '-f'],
            ['File test', 'readable by eff. UID/GID', '-r'],
            ['File test', 'readable by real UID/GID', '-R'],
            ['File test', 'setgid bit set', '-g'],
            ['File test', 'setuid bit set', '-u'],
            ['File test', 'socket', '-S'],
            ['File test', 'sticky bit set', '-k'],
            ['File test', 'symbolic link', '-l'],
            ['File test', 'text file', '-T'],
            ['File test', 'writable by eff. UID/GID', '-w'],
            ['File test', 'writable by real UID/GID', '-W'],
            ['File test', 'zero size', '-z'],
            ['Pod', 'pod/cut', "=pod\n\n\n\n=cut\n"],
            ['Regex','grouping','()'],
            ['Statement','foreach',"foreach my \$ (  ) {\n}\n"],
            ['Statement','if',"if (  ) {\n}\n"],
            ['Statement','do while',"do {\n\n	    }\n	    while (  );\n"],
            ['Statement','for',"for ( ; ; ) {\n}\n"],
            ['Statement','foreach',"foreach my $ (  ) {\n}\n"],
            ['Statement','if',"if (  ) {\n}\n"],
            ['Statement','if else { }',"if (  ) {\n} else {\n}\n"],
            ['Statement','unless ',"unless (  ) {\n}\n"],
            ['Statement','unless else',"unless (  ) {\n} else {\n}\n"],
            ['Statement','until',"until (  ) {\n}\n"],
            ['Statement','while',"while (  ) {\n}\n"],
        );
        my $sth = $class->prepare('INSERT INTO snippets (category,name,snippet) VALUES (?, ?, ?)');
        $sth->execute($_->[0], $_->[1], $_->[2]) for @prepsnips;
    }

    #
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





#####################################################################
# Snippets

sub add_snippet {
	my ($class, $category, $name, $value) = @_;

	$class->do(
		"INSERT INTO snippet ( category, name, value ) VALUES ( ?, ?, ? )",
		{}, $category, $name, $value,
	);
	return;
}

sub find_snipclasses {
	my ($class, $part) = @_;

	my $sql   = "SELECT distinct category FROM snippets";
	my @bind_values;
	if ( $part ) {
		$sql .= " WHERE category LIKE ?";
		push @bind_values, '%' . $part .  '%';
	}
	$sql .= " ORDER BY category";
	return $class->selectcol_arrayref($sql, {}, @bind_values);
}

sub find_snipnames {
	my ($class, $part) = @_;

	my $sql   = "SELECT name FROM snippets";
	my @bind_values;
	if ( $part ) {
		$sql .= " WHERE category LIKE ?";
		push @bind_values, '%' . $part .  '%';
	}
	$sql .= " ORDER BY name";
	return $class->selectcol_arrayref($sql, {}, @bind_values);
}

sub find_snippets {
	my ($class, $part) = @_;

	my $sql   = "SELECT snippet FROM snippets";
	my @bind_values;
	if ( $part ) {
		$sql .= " WHERE category LIKE ?";
		push @bind_values, '%' . $part .  '%';
	}
	$sql .= " ORDER BY name";
	return $class->selectcol_arrayref($sql, {}, @bind_values);
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
