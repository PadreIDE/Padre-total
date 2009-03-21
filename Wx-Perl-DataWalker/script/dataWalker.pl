#!/usr/bin/env perl
use strict;
use warnings;
use Wx;
use Wx::Perl::DataWalker;
use YAML::XS;
use Getopt::Long qw(GetOptions);

sub usage {
  my $msg = shift;
  warn("$msg\n\n") if defined $msg;

  warn <<HERE;
Usage: $0 YAMLDUMP
HERE
  exit(1);
}

GetOptions(
  'h|help' => \&usage,
);

my $datafile = shift(@ARGV);
usage("Need find YAML input file") unless defined $datafile;
usage("Could not find YAML input file '$datafile'") unless -f $datafile;
my $data = YAML::XS::LoadFile($datafile);

package MyApp;
our @ISA = qw(Wx::App);

sub OnInit {
    my $self = shift;

    my $frame = Wx::Perl::DataWalker->new(
      {data => $data},
      undef, -1,
      "Hello World",
      [250, 250], [300, 300],
      Wx::wxDEFAULT_FRAME_STYLE 
    );
    $frame->Show(1);

    $self->SetTopWindow($frame);

    return 1;
}


package main;
my $app = MyApp->new();
$app->MainLoop();

