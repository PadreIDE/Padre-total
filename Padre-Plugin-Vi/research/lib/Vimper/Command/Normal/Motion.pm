package Vimper::Command::Normal::Motion;

use 5.010;
use Moose;
use Moose::Autobox;
use MooseX::Method::Signatures;
use MooseX::Has::Sugar;
use Vimper::Types qw(SheetBool SheetTriState);
use aliased 'Vimper::SyntaxPath';
use aliased 'Vimper::SyntaxPath::Node::Init'    => 'InitNode';
use aliased 'Vimper::SyntaxPath::Node::Count'   => 'CountNode';
use aliased 'Vimper::SyntaxPath::Node::Op'      => 'OpNode';
use aliased 'Vimper::SyntaxPath::Node::Letter'  => 'LetterNode';
use aliased 'Vimper::SyntaxPath::Node::Char'    => 'CharNode';
use aliased 'Vimper::SyntaxPath::Node::Command' => 'CommandNode';

# a normal mode motion command

extends 'Vimper::Command::Normal';

map { has $_->[0], isa => $_->[1], ro, required, coerce }
     [count  => SheetTriState] # can't, can, or must be prefixed with count
    ,[op     => SheetTriState] # can't, can, or must be motion of an op
    ,[char   => SheetBool]     # not or must be followed by a char
    ,[letter => SheetBool]     # not or must be followed by a letter
    ;

my ($COUNT, $OP, $CHAR, $LETTER) = 0..3;
my @Syntax_Space = _combs(map { [0..1] } 1..4);

# two normal mode motion commands are in the same syntax group if their syntax
# paths are identical
method syntax_group {
    my ($count, $op, $char, $letter, $first_key) = map { $self->$_ }
        qw(count op char letter first_key);
    my $key_count = scalar $self->key_list->flatten;
    my $keys = $key_count == 1? $key_count: "$key_count.$first_key";
    return "op=$op:count=$count:keys=$keys:char=$char:letter=$letter";
}

method _build_syntax_paths() {
    my ($keys, $count, $op, $char, $letter) = map { $self->$_ }
        qw(keys count op char letter);
    my @paths;

    # search all possible grammars for VIM normal motion commands
    # and filter those the command does not allow

    for my $comb (@Syntax_Space) {
        next if (($count == 0) && $comb->[$COUNT])
             || (($count == 2) && !$comb->[$COUNT])
             || (($op    == 0) && $comb->[$OP])
             || (($op    == 2) && !$comb->[$OP])
             || ($char   != $comb->[$CHAR])
             || ($letter != $comb->[$LETTER]);

        push @paths, SyntaxPath->new(parts => [
            InitNode->new,
            ($comb->[$OP]    ? OpNode->new    : ()),
            ($comb->[$COUNT ]? CountNode->new : ()),
            $self->key_list->flatten,
            ($comb->[$CHAR]  ? CharNode->new  : ()),
            ($comb->[$LETTER]? LetterNode->new: ()),
            CommandNode->new(command => $self),
        ]);
    }
    return \@paths;
}

# find all possible values in a combination of several params
# in  - list of array refs, in each a list of possible values for some param
# out - list of array refs, in each a list of the values chosen for each param
# e.g. _combs([0,1], [2,3]) == ([0,2], [0,3], [1,2], [1,3])
sub _combs {
    my @in = @_;
    return map { [$_] } @{ $in[0] } if @in == 1;
    my @last = @{ pop @in };
    return map
        { my @out = @{ $_ }; map { [@out, $_] } @last; }
        _combs(@in);
}

1;

