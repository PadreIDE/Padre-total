package Locale::Msgfmt::mo;

use strict;
use warnings;

our $VERSION = '0.05';

use Locale::Msgfmt::Utils;

sub new {
  return bless {}, shift;
}

sub initialize {
  my $self = shift;
  $self->{magic} = "0x950412de";
  $self->{format} = 0;
  $self->{strings} = {};
}

sub add_string {
  my ($self, $string, $translation) = @_;
  $self->{strings}->{$string} = $translation;
}

sub prepare {
  my $self = shift;
  $self->{count} = scalar keys %{$self->{strings}};
  $self->{free_mem} = 28 + $self->{count} * 16;
  @{$self->{sorted}} = sort keys %{$self->{strings}};
  @{$self->{translations}} = ();
  foreach(@{$self->{sorted}}) {
    push @{$self->{translations}}, $self->{strings}->{$_};
  }
}

sub out {
  my $self = shift;
  my $file = shift;
  open OUT, ">", $file;
  binmode OUT;
  print OUT Locale::Msgfmt::Utils::from_hex($self->{magic});
  print OUT Locale::Msgfmt::Utils::character($self->{format});
  print OUT Locale::Msgfmt::Utils::character($self->{count});
  print OUT Locale::Msgfmt::Utils::character(28);
  print OUT Locale::Msgfmt::Utils::character(28 + $self->{count} * 8);
  print OUT Locale::Msgfmt::Utils::character(0);
  print OUT Locale::Msgfmt::Utils::character(0);
  foreach(@{$self->{sorted}}) {
    my $length = length($_);
    print OUT Locale::Msgfmt::Utils::character($length);
    print OUT Locale::Msgfmt::Utils::character($self->{free_mem});
    $self->{free_mem} += $length + 1;
  }
  foreach(@{$self->{translations}}) {
    my $length = length($_);
    print OUT Locale::Msgfmt::Utils::character($length);
    print OUT Locale::Msgfmt::Utils::character($self->{free_mem});
    $self->{free_mem} += $length + 1;
  }
  foreach(@{$self->{sorted}}) {
    print OUT Locale::Msgfmt::Utils::null_terminate($_);
  }
  foreach(@{$self->{translations}}) {
    print OUT Locale::Msgfmt::Utils::null_terminate($_);
  }
  close OUT;
}

1;
