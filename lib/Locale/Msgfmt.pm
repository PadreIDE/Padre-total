package Locale::Msgfmt;

use Locale::Msgfmt::mo;
use Locale::Msgfmt::po;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw/msgfmt/;

our $VERSION = '0.01';

sub msgfmt {
  my $hash = shift;
  if(! -f $hash->{in}) {
    print "error: input file does not exist\n";
    exit(1);
  }
  my $mo = Locale::Msgfmt::mo->new();
  $mo->initialize();
  my $po = Locale::Msgfmt::po->new({fuzzy => $hash->{fuzzy}});
  $po->parse($hash->{in}, $mo);
  $mo->prepare();
  $mo->out($hash->{out});
}

1;

=head1 NAME

Locale::Msgfmt - Compile .po files to .mo files

=head1 SYNOPSIS

This module does the same thing as msgfmt from GNU gettext-tools,
except this is pure Perl.

    use Locale::Msgfmt;

    msgfmt({in => "po/fr.po", out => "po/fr.mo"})

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ryan Niebur, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
