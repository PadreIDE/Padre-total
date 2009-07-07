package Padre::Plugin::IntelliPerl;

use base 'Padre::Plugin';
use strict;
use Padre::Wx;
use Padre::Util qw/_T/;
use Padre::Current;
use Devel::IntelliPerl;

our $VERSION = '0.01';

sub plugin_name {
  return "IntelliPerl";
}

sub menu_plugins_simple {
  my $self = shift;
  return $self->plugin_name => [
                                'Intellicomplete\tCtrl-I' => sub { $self->intellicomplete },
                               ];
}

sub padre_interfaces {
        return 'Padre::Plugin' => '0.26';
      }

sub intellicomplete {
  my $self = shift;
  my $doc = Padre::Current->document;
  my $editor = $doc->editor;
  my $pos    = $editor->GetCurrentPos;
  my $line   = $editor->LineFromPosition($pos);
  my $first  = $editor->PositionFromLine($line);
  my $col = $pos - $first;
  $line = $line + 1;
  $col = $col + 1;
  my $source = $editor->GetText();
  my $ip = Devel::IntelliPerl->new(source => $source, line_number => $line, column => $col);
  my @list = $ip->methods();
  my $prefix = $ip->prefix();
  if(@list) {
    $editor->AutoCompShow( length($prefix), join " ", @list );
  }
}

1;

=head1 NAME

foo - foo

=cut
