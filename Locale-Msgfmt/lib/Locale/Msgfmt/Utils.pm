package Locale::Msgfmt::Utils;

use strict;
use warnings;

our $VERSION = '0.04';

sub character {
  return map {pack "N*", $_} @_;
}

sub _from_character {
  return map {ord($_)} @_;
}

sub from_character {
  return character(_from_character(@_));
}

sub _from_hex {
  return map {hex($_)} @_;
}

sub from_hex {
  return character(_from_hex(@_));
}

sub _from_string {
  return split //, join '', @_;
}

sub from_string {
  return join_string(from_character(_from_string(@_)));
}

sub join_string {
  return join '', @_;
}

sub number_to_s {
  return sprintf "%d", shift;
}

sub null_terminate {
  return pack "Z*", shift;
}

sub null {
  return null_terminate("");
}

1;
