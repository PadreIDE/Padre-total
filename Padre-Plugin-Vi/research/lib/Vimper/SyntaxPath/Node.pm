package Vimper::SyntaxPath::Node;

use 5.010;
use Moose;
use Moose::Autobox;
use MooseX::Method::Signatures;
use MooseX::Has::Sugar;

# base class for a node in a syntax path
# each node in the syntax of a normal mode motion command is modeled as
# one of the subclasses:
#
# init - start here
# key - e.g. the "h" in move left one char
# optional: more keys - e.g. "iw"
# optional: a count
# optional: a letter (e.g. a mark)
# optional: a char (e.g. following "f")
# optional: an operator which allows trailing motion (e.g. "d" or "y")
# command - the actual command to trigger

method type {
    my ($class) = ref($self) =~ /::(\w+)$/;
    return lc($class);
}

method graph_name     { $self->type }
method graph_label    { $self->type }
method bag_key        { undef }
method label_sep      { undef }
method must_merge     { 0 }            # init & op nodes must be merged when merging
method must_not_merge { 0 }            # command,letter,char nodes can't be merged
                                       # count node could be merged, key-1 nodes could
                                       # be merged if key is 'g' or 'm'

method to_string { die "Abstract method called" }

method escaped_to_string {
    my $s = $self->to_string;
    $s =~ s/"/\\"/g;
    return $s;
}

1;
