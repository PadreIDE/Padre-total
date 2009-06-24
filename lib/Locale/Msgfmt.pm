package Locale::Msgfmt;

use Locale::Msgfmt::mo;
use Locale::Msgfmt::po;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw/msgfmt/;

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
