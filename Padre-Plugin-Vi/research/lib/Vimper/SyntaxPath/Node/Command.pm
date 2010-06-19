package Vimper::SyntaxPath::Node::Command;

use 5.010;
use Moose;
use Moose::Autobox;
use MooseX::Method::Signatures;
use MooseX::Has::Sugar;
use aliased 'Vimper::Command::Normal::Motion' => 'Command';

extends 'Vimper::SyntaxPath::Node';

has command => (ro, required, isa => Command);

method graph_label    { $self->to_string }
method bag_key        { 'vimperCommands' }
method label_sep      { "\\n" }
method must_not_merge { 1 }

method to_string { $self->command->keys. ": ". $self->command->help }

1;
