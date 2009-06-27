#!/usr/bin/perl

use Locale::Msgfmt;
use Getopt::Long;

use strict;
use warnings;

my($opt_o, $opt_f);
GetOptions("output-file|o=s" => \$opt_o, "use-fuzzy|f" => \$opt_f);
my $in = shift;

msgfmt({in => $in, out => $opt_o, fuzzy => $opt_f});

=head1 NAME

msgfmt.pl - Compile .po files to .mo files

=head1 SYNOPSIS

This script does the same thing as msgfmt from GNU gettext-tools,
except this is pure Perl. Because it's pure Perl, it's more portable
and more easily installed (via CPAN). It has two other advantages.
First, it supports directories, so you can have it process a full
directory of .po files. Second, it can guess the output file (if you
don't specify the -o option). If the input is a file, it will
s/po$/mo/ to figure out the output file. If the input is a directory,
it will write the .mo files to the same directory.

=head1 SEE ALSO

L<Locale::Msgfmt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ryan Niebur, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
