package Locale::Msgfmt;

use Locale::Msgfmt::mo;
use Locale::Msgfmt::po;
use File::Path;
use File::Spec;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw/msgfmt msgfmt_dir/;

our $VERSION = '0.06';

sub msgfmt {
  my $hash = shift;
  if(!defined($hash)) {
    die("error: must give input");
  }
  if(!(ref($hash) eq "HASH")) {
    $hash = {in => $hash};
  }
  if(!defined($hash->{in}) or !length($hash->{in})) {
    die("error: must give an input file");
  }
  if(! -e $hash->{in}) {
    die("error: input does not exist");
  }
  if(-d $hash->{in}) {
    return _msgfmt_dir($hash);
  } else {
    return _msgfmt($hash);
  }
}

sub msgfmt_dir {
  return msgfmt(@_);
}

sub _msgfmt {
  my $hash = shift;
  if(! defined($hash->{in})) {
    die("error: must give an input file");
  }
  if(! -f $hash->{in}) {
    die("error: input file does not exist");
  }
  if(! defined($hash->{out})) {
    if($hash->{in} =~ /\.po$/) {
      $hash->{out} = $hash->{in};
      $hash->{out} =~ s/po$/mo/;
    } else {
      die("error: must give an output file");
    }
  }
  my $mo = Locale::Msgfmt::mo->new();
  $mo->initialize();
  my $po = Locale::Msgfmt::po->new({fuzzy => $hash->{fuzzy}});
  $po->parse($hash->{in}, $mo);
  $mo->prepare();
  $mo->out($hash->{out});
}

sub _msgfmt_dir {
  my $hash = shift;
  if(! -d $hash->{in}) {
    die("error: input directory does not exist");
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
    _msgfmt(\%newhash);
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
    msgfmt({in => "po/fr.po", out => "po/fr.mo", fuzzy => 1});
    msgfmt("po/");
    msgfmt({in => "po/", out => "output/"});
    msgfmt("po/fr.po");
    msgfmt({in => "po/fr.po", fuzzy => 1});

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ryan Niebur, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
