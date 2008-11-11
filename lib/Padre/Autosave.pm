package Padre::Autosave;

use strict;
use warnings;

our $VERSION = '0.01';


=head1 NAME

Padre::Autosave - autosave and recovery mechanism for Padre

=head1 SYNOPSIS

 my $autosave = Padre:Autosave->new(db => 'path/to/database');
 $autosave->save($path, $timestamp, $type, $data) = @_;


=head1 DESCRIPTION



=head1 The longer autosave plan

The following is just a plan that is currently shelved as some people
on the Padre development list think this is not ncessary and one
should use a real version control for this anyway.

So I leave it here for now, for future exploration.

I'd like to provide autosave with some history and recovery service.

While I am writing this for Padre I'll make the code separate
so others can use it.

An sqlite database will be used for this but theoretically
any database could be used. Event plain filesystem.

Basically this will provide a versioned filesystem with
metadata and autocleanup.

Besides the content of the file we need to save some meta data:
- path to the file will be the unique identifyer
- timestamp
- type of save (initial, autosave, usersave, external)


When opening a file for the first time it is saved in the database.(initial)

Every N seconds files that are not currently in "saved" situation
are autosaved in the database making sure that they are only saved
if they differ from the previous state. (autosave)

Evey time a file is saved it is also saved to the database. (usersave)
Before reloading a file we autosave it. (autosave)

Every time we notice that a file was changed on the disk if the user decides 
to overwrite it we also save the (external) changed file.

Before autosaving a file we make sure it has not changed since the 
last autosave.

In order to make sure the database does not get too big we setup 
a cleaning mechanizm that is executed once in a while.
There might be several options but for now:
1) Every entry older than N days will be deleted.


Based on the database we'll be able to provide the user recovery in
case of crash or accidental overwrite.

When opening padre we should check if there are files in the database
that the last save was NOT usersave and offer recovery.

When opening a file we should also check how is it related
to the last save in the database.

For buffers that were never saved and so have no filenames
we should have some internal identifier in Padre and use that 
for the autosave till the first usersave.

The same mechanizm will be really useful when we start
providing remote editing. Then a file is identifyed by 
its URI 
( ftp://machine/path/to/file or scp://machine/path/to/file )


my @types = qw(initial, autosave, usersave, external);

sub save_data {
	my ($path, $timestamp, $type, $data) = @_;
}

=cut


1;
