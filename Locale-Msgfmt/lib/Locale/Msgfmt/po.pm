package Locale::Msgfmt::po;

use strict;
use warnings;

our $VERSION = '0.04';

sub new {
  my $class = shift;
  return bless shift || {}, $class;
}

sub cleanup_string {
  my $str = shift;
  $str =~ s/\\n/\n/g;
  $str =~ s/\\r/\r/g;
  $str =~ s/\\t/\t/g;
  $str =~ s/\\"/"/g;
  $str =~ s/\\\\/\\/g;
  return $str;
}

sub add_string {
  my $self = shift;
  my $hash = shift;
  my %h = %{$hash};
  return if !(defined($h{msgid}) && defined($h{msgstr}));
  return if ($h{fuzzy} && !$self->{fuzzy} && length($h{msgid}) > 0);
  return if($h{msgstr} eq "");
  $self->{mo}->add_string(cleanup_string($h{msgid}), cleanup_string($h{msgstr}));
}

sub read_po {
  my $self = shift;
  my $pofile = shift;
  my $mo = $self->{mo};
  open F, $pofile;
  my %h = ();
  my $type;
  while (<F>) {
    s/\r\n/\n/;
    if(/^(msgid|msgstr) +"(.*)" *$/) {
      $type = $1;
      if($type eq "msgid" && defined($h{msgid})) {
        $self->add_string(\%h);
        %h = ();
      }
      $h{$type} = $2;
    }
    elsif(/^"(.*)" *$/) {
      $h{$type} .= $1;
    }
    elsif(/^ *$/) {
      $self->add_string(\%h);
      %h = ();
      $type = undef;
    } elsif(/^#/) {
      if(/^#, fuzzy/) {
        $h{fuzzy} = 1;
      } elsif (/^#:/) {
        if(defined($h{msgid})) {
          $self->add_string(\%h);
          %h = ();
          $type = undef;
        }
      }
    } else {
      print "unknown line: " . $_ . "\n";
    }
  }
  $self->add_string(\%h);
  close F;
}

sub parse {
  my $self = shift;
  my ($pofile, $mo) = @_;
  $self->{mo} = $mo;
  $self->read_po($pofile);
}

1;
