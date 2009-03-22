package Wx::Perl::DataWalker;
use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';
our @ISA = qw(Wx::Frame);

use Scalar::Util qw(reftype blessed refaddr);
use Wx ':everything';
use Wx::Event ':everything';
require Wx::Perl::DataWalker::CurrentLevel;

use Class::XSAccessor
  getters => {
    stack        => 'stack',
  },
  accessors => {
    current_head => 'current_head',
  };


sub new {
  my $class = shift;
  my $config = shift;
  my $self = $class->SUPER::new(@_);

  $self->{global_head} = $config->{data} or die "Invalid data";
  my $rtype = reftype($self->{global_head});
  die "top-level display of CODE refs not supported!" if defined $rtype and $rtype eq 'CODE';

  my $hsizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);

  # tree view here...
#  $self->{current_level2} = Wx::Button->new(
#    $self, -1, "FOOO",
#    Wx::wxDefaultPosition,
#    Wx::wxDefaultSize,
#  );
#  $hsizer->Add($self->{current_level2}, Wx::wxEXPAND, Wx::wxEXPAND, Wx::wxALL, 2);

  my $buttonsizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
  $self->{back_button} = Wx::Button->new(
    $self, -1, "<--",
  );
  EVT_BUTTON( $self, $self->{back_button}, sub { $self->go_back(); } );
  $buttonsizer->Add($self->{back_button}, 0, 0, Wx::wxALL, 2);
  
  $self->{reset_button} = Wx::Button->new(
    $self, -1, "Reset",
  );
  EVT_BUTTON( $self, $self->{reset_button}, sub { $self->reset(); } );
  $buttonsizer->Add($self->{reset_button}, 0, 0, Wx::wxALL, 2);

  my $vsizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
  $vsizer->Add($buttonsizer, 0, Wx::wxEXPAND, Wx::wxALL, 2);
  
  # the current level in the tree...
  $self->{current_level} = Wx::Perl::DataWalker::CurrentLevel->new(
    $self, -1,
  );
  $vsizer->Add($self->{current_level}, Wx::wxEXPAND, Wx::wxEXPAND, Wx::wxALL, 2);
  

  
  $hsizer->Add($vsizer, Wx::wxEXPAND, Wx::wxEXPAND, Wx::wxALL, 2);


  $self->SetSizer( $hsizer );
  $hsizer->SetSizeHints( $self );

  $self->reset();

  return $self;
}

sub go_down {
  my $self = shift;
  my $where = shift;

  my $data = $self->current_head;
  my $target;
  my $reftype = reftype($data);
  if (!$reftype) {
    return();
  }
  elsif ($reftype eq 'SCALAR') {
    $target = $$data;
  }
  elsif ($reftype eq 'HASH') {
    $target = $data->{$where};
  }
  elsif ($reftype eq 'ARRAY') {
    $target = $data->[$where];
  }
  elsif ($reftype eq 'REF') {
    $target = $$data;
  }
  elsif ($reftype eq 'GLOB') {
    $target = *{$data}{$where};
  }
  else {
    return();
  }

  my $treftype = reftype($target);
  if (not $treftype and reftype(\$target) eq 'GLOB') {
    # work around my sucky understanding of GLOBS. Damn you, GLOB, damn you!
#    $self->current_head(\$target);
#    push @{$self->stack}, \$target;
#    $self->{current_level}->set_data(\$target);
#    return(1);
    # with kudos to Yves!    
    no strict 'refs';
    $target = \*{"$target"};
    $treftype = reftype($target);
  }
  return() if not $treftype or $treftype eq 'CODE';
  # avoid direct recursion into self
  return() if $treftype eq $reftype and refaddr($target) eq refaddr($data);

  $self->current_head($target);
  push @{$self->stack}, $target;
  $self->{current_level}->set_data($target);
  return(1);
}

sub go_back {
  my $self = shift;
  my $stack = $self->stack;

  return() if @$stack == 1;
  
  pop(@$stack);
  $self->current_head($stack->[-1]);
  $self->{current_level}->set_data($stack->[-1]);
  
  return(1);
}


sub reset {
  my $self = shift;
  $self->{stack} = [$self->{global_head}];
  $self->current_head($self->{global_head});
  $self->{current_level}->set_data($self->current_head);
}

1;
__END__

=head1 NAME

Wx::Perl::DataWalker - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Wx::Perl::DataWalker;

=head1 DESCRIPTION

Stub documentation for Wx::Perl::DataWalker, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 SEE ALSO

L<Wx>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
