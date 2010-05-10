package Vimper::SyntaxPath::Node::Key;

use 5.010;
use Moose;
use Moose::Autobox;
use MooseX::Method::Signatures;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(Str Int);

extends 'Vimper::SyntaxPath::Node';

has key => (ro, required, isa => Str);
has idx => (ro, required, isa => Int);

method to_string { 'key'. $self->idx. ':'. $self->key }

method graph_label { $self->key }
method graph_name  { 'key'. $self->idx }
method bag_key     { 'vimperKeys' }
method label_sep   { " " }

method escaped_key {
    my $key = $self->key;
    (my $clean_key = $key) =~ s/"/\\"/g;
    return $clean_key;
}

1;
