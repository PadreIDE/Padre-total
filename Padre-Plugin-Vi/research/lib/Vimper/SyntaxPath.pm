package Vimper::SyntaxPath;

use 5.010;
use Moose;
use Moose::Autobox;
use MooseX::Method::Signatures;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(ArrayRef);
use aliased 'Vimper::SyntaxPath::Node';

# a possible path of nodes for a command
# e.g. for the command "h", one path would be a list of the nodes:
# (count, key "h")

has parts => (ro, required, isa => ArrayRef[Node]);

method to_string
    { $self->parts->map(sub { $_->to_string })->join("\t") }

method command   { $self->parts->[-1]->command }
method key_list  { $self->parts->grep(sub{ ref($_) =~ /KeyNode/ }) }
method key_count { scalar $self->key_list->flatten }

1;
