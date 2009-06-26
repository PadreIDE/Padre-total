package Locale::Msgfmt;

use Locale::Msgfmt::mo;
use Locale::Msgfmt::po;
use File::Path;
use File::Spec;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw/msgfmt msgfmt_dir/;

our $VERSION = '0.05';

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

sub msgfmt_dir {
  my $hash = shift;
  if(! -d $hash->{in}) {
    print "error: input directory does not exist\n";
    exit(1);
  }
  if(! defined($hash->{out})) {
    $hash->{out} = $hash->{in};
  }
  if(! -d $hash->{out}) {
    File::Path::mkpath($hash->{out});
  }
  opendir D, $hash->{in};
  my @list = readdir D;
  closedir D;
  @list = grep /\.po$/, @list;
  my %files;
  foreach(@list) {
    my $in = File::Spec->catfile($hash->{in}, $_);
    my $out = File::Spec->catfile($hash->{out}, substr($_, 0, -3) . ".mo");
    $files{$in} = $out;
  }
  delete $hash->{in};
  delete $hash->{out};
  foreach(keys %files) {
    my %newhash = (%{$hash});
    $newhash{in} = $_;
    $newhash{out} = $files{$_};
    msgfmt(\%newhash);
  }
}

1;

=head1 NAME

Locale::Msgfmt - Compile .po files to .mo files

=head1 SYNOPSIS

This module does the same thing as msgfmt from GNU gettext-tools,
except this is pure Perl.

    use Locale::Msgfmt;

    msgfmt({in => "po/fr.po", out => "po/fr.mo"});
    msgfmt_dir({in => "po/"});

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ryan Niebur, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
