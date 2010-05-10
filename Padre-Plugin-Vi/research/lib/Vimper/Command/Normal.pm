package Vimper::Command::Normal;

use 5.010;
use Moose;
use Moose::Autobox;
use MooseX::Method::Signatures;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(Str ArrayRef);
use Vimper::Types qw(StrList);
use aliased 'Vimper::SyntaxPath';
use aliased 'Vimper::SyntaxPath::Node::Key' => 'KeyNode';

# base class for normal mode commands
# they all have a sequence of keys that will trigger them
# they may have other sequences
# they all have help

map { has $_->[0], isa => $_->[1], ro, required, coerce }
     [keys     => Str],
    ,[synonyms => StrList] # TODO not used yet
    ,[help     => Str],
    ;

has key_list     => (ro, lazy_build, isa => ArrayRef[KeyNode]);
has syntax_paths => (ro, lazy_build, isa => ArrayRef[SyntaxPath]);

# from the string description in VIM ref, build a list of key nodes
method _build_key_list {
    my $keys = $self->keys;
    my @keys;
    while (length $keys) {
        # 3 forms of keys in VIM docs
        push(@keys, $1) if $keys =~ s/^(CTRL-.)//;
        push(@keys, $1) if $keys =~ s/^(<[^>]+>)//;
        push(@keys, $1) if $keys =~ s/^(.)//;
    }
    my $i = 1;
    return [@keys]->map(sub{ KeyNode->new(key => $_, idx => $i++) });
}

method first_key { $self->key_list->[0]->key }

# list of all paths that can be traversed to trigger the command
method _build_syntax_paths() { die "Abstract method called" }

method to_string { $self->keys. ": ". $self->help }

1;
