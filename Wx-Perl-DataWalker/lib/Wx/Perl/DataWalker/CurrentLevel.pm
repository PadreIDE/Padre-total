package Wx::Perl::DataWalker::CurrentLevel;
use 5.008001;
use strict;
use warnings;

use Scalar::Util qw(blessed reftype weaken);
use Wx;
our $VERSION = '0.01';
our @ISA = qw(Wx::ListCtrl);

use constant {
  DISPLAY_UNINITIALIZED => 0,
  DISPLAY_SCALAR        => 1,
  DISPLAY_ARRAY         => 2,
  DISPLAY_HASH          => 3,
  DISPLAY_GLOB          => 4,
};

use constant GLOB_THINGS => [qw(NAME PACKAGE SCALAR ARRAY HASH CODE IO GLOB FORMAT)];
  #$scalarref = *foo{SCALAR};
  #$arrayref  = *ARGV{ARRAY};
  #$hashref   = *ENV{HASH};
  #$coderef   = *handler{CODE};
  #$ioref     = *STDIN{IO};
  #$globref   = *foo{GLOB};
  #$formatref = *foo{FORMAT};

use Class::XSAccessor
  getters => {
    parent => 'parent',
  };

sub new {
  my $class = shift;
  my ($parent, $id, $pos, $size) = @_;
  my $self = $class->SUPER::new(
    $parent, $id, $pos||Wx::wxDefaultPosition, $size||Wx::wxDefaultSize, Wx::wxLC_REPORT|Wx::wxLC_VIRTUAL
  );
  $self->{parent} = $parent;
  weaken($self->{parent});

  # Double-click a function name
  Wx::Event::EVT_LIST_ITEM_ACTIVATED( $self, $self,
    sub {
      $self->on_list_item_activated($_[1]);
    }
  );
  
  $self->{display_mode} = DISPLAY_UNINITIALIZED;
  $self->set_data('');

  return $self;
}

sub set_data {
  my $self = shift;
  my $data = shift;

  my $reftype = reftype($data);
  return() if defined $reftype and $reftype eq 'CODE';
  
  $self->{data} = $data;
  delete $self->{hash_cache};

  if (!$reftype) {
    $self->_set_scalar();
  }
  elsif ($reftype eq 'HASH') {
    $self->_set_hash();
  }
  elsif ($reftype eq 'ARRAY') {
    $self->_set_array();
  }
  elsif ($reftype eq 'GLOB') {
    $self->_set_glob();
  }
  else {
    $self->_set_scalar();
  }

  $self->_set_width;
  return(1);
}

#####################################
# display methods

sub OnGetItemText {
  my $self = shift;
  my $itemno = shift;
  my $colno  = shift;
  my $data = $self->{data};

  if ($self->{display_mode} == DISPLAY_SCALAR) {
    $colno == 0 and return reftype($data)||'';
    $colno == 1 and return blessed($data)||'';
    return defined($$data)?$$data:'undef';
  }
  elsif ($self->{display_mode} == DISPLAY_ARRAY) {
    $colno == 0 and return $itemno;
    my $item = $data->[$itemno];
    $colno == 1 and return reftype($item)||'';
    $colno == 2 and return blessed($item)||'';
    return defined($item)?$item:'undef';
  }
  elsif ($self->{display_mode} == DISPLAY_HASH) {
    my $key = $self->{hash_cache}[$itemno];
    $colno == 0 and return $key;
    my $item = $data->{$key};
    $colno == 1 and return reftype($item)||'';
    $colno == 2 and return blessed($item)||'';
    return defined($item)?$item:'undef';
  }
  elsif ($self->{display_mode} == DISPLAY_GLOB) {
    $colno == 0 and return GLOB_THINGS->[$itemno];
    my $item = *{$data}{GLOB_THINGS->[$itemno]};
    $colno == 1 and return reftype($item)||'';
    $colno == 2 and return blessed($item)||'';
    return defined($item)?$item:'undef';
  }

}


{
  # this is an optimization explicitly allowed according to the wx docs.
  my $undef_attr = Wx::ListItemAttr->new();
  $undef_attr->SetTextColour(Wx::Colour->new("gray"));

  sub OnGetItemAttr {
    my $self = shift;
    my $itemno = shift;
    my $data = $self->{data};

    # colour the undef's gray!
    if ($self->{display_mode} == DISPLAY_SCALAR) {
      return defined($$data) ? undef : $undef_attr;
    }
    elsif ($self->{display_mode} == DISPLAY_ARRAY) {
      my $item = $data->[$itemno];
      return defined($item) ? undef : $undef_attr;
    }
    elsif ($self->{display_mode} == DISPLAY_HASH) {
      my $key = $self->{hash_cache}[$itemno];
      my $item = $data->{$key};
      return defined($item) ? undef : $undef_attr;
    }
    elsif ($self->{display_mode} == DISPLAY_GLOB) {
      my $item = *{$data}{GLOB_THINGS->[$itemno]};
      return defined($item) ? undef : $undef_attr;
    }
  }
}

######################
# setup the display data type

sub _set_scalar {
  my $self = shift;
  $self->{display_mode} = DISPLAY_SCALAR;
  $self->ClearAll();
  $self->SetItemCount(1);
  $self->InsertColumn(0, "RefType");
  $self->InsertColumn(1, "Class");
  $self->InsertColumn(2, "Value");
  return();
}

sub _set_hash {
  my $self = shift;
  
  $self->{display_mode} = DISPLAY_HASH;
  $self->ClearAll();
  $self->SetItemCount(scalar keys %{$self->{data}});
  $self->{hash_cache} = [sort keys %{$self->{data}}];
  $self->InsertColumn(0, "Key");
  $self->InsertColumn(1, "RefType");
  $self->InsertColumn(2, "Class");
  $self->InsertColumn(3, "Value");
  return();
}

sub _set_array {
  my $self = shift;

  $self->{display_mode} = DISPLAY_ARRAY;
  $self->ClearAll();
  $self->SetItemCount(scalar @{$self->{data}});
  $self->InsertColumn(0, "Index");
  $self->InsertColumn(1, "RefType");
  $self->InsertColumn(2, "Class");
  $self->InsertColumn(3, "Value");
  return();
}


sub _set_glob {
  my $self = shift;
  $self->{display_mode} = DISPLAY_GLOB;
  $self->ClearAll();
  $self->SetItemCount(scalar @{GLOB_THINGS()});
  $self->InsertColumn(0, "THING");
  $self->InsertColumn(1, "RefType");
  $self->InsertColumn(2, "Class");
  $self->InsertColumn(3, "Value");
  return();
}


sub _set_width {
  my $self = shift;
# Can't work in virtual mode...
#  foreach my $col (0..$cols-1) {
#    $self->SetColumnWidth( $col, Wx::wxLIST_AUTOSIZE );
#    $self->SetColumnWidth( $col, 70 ) if $self->GetColumnWidth( $col ) < 70;
#  }
  
  my $widths;
  for ($self->{display_mode}) {
    if ($_ == DISPLAY_SCALAR) {
      $widths = [80, 90, 200];
    }
    elsif ($_ == DISPLAY_ARRAY) {
      my $chars = length(scalar(@{$self->{data}}));
      $chars = 6 if $chars < 6;
      $widths = [$chars*11, 80, 90, 200];
    }
    elsif ($_ == DISPLAY_HASH) {
      $widths = [100, 80, 90, 200];
    }
    elsif ($_ == DISPLAY_GLOB) {
      $widths = [100, 80, 90, 200];
    }
  }
  return() unless $widths;

  my $cols = $self->GetColumnCount();
  foreach my $col (0..$cols-1) {
    $self->SetColumnWidth( $col, $widths->[$col] );
  }
  
}



###################################
# event handlers

sub on_list_item_activated {
  my $self = shift;
  my $event = shift;

  my $row  = $event->GetIndex();
  #my $col  = $event->GetColumn();

  my $key;
  for ($self->{display_mode}) {
    $_ == DISPLAY_SCALAR and $key = undef, last;
    $_ == DISPLAY_ARRAY  and $key = $row, last;
    $_ == DISPLAY_HASH   and $key = $self->{hash_cache}[$row], last;
    $_ == DISPLAY_GLOB   and $key = GLOB_THINGS->[$row], last;
  }

  $self->parent->go_down($key);
}


1;
__END__

