package Vimper::SyntaxDag;

use 5.010;
use Moose;
use Moose::Autobox;
use MooseX::Method::Signatures;
use MooseX::Has::Sugar;
use Graph;
use Graph::Writer::Dot;
use MooseX::Types::Moose qw(HashRef ArrayRef);
use aliased 'Vimper::CommandSheet';
use aliased 'Vimper::Command::Normal' => 'NormalCommand';
use aliased 'Vimper::SyntaxPath::Node::Init';
use aliased 'Vimper::SyntaxDag::GroupList';

# TODO merge the group graphs here

has src        => (ro, required  , isa => CommandSheet);
has dag        => (ro, lazy_build, isa => 'Graph');
has group_list => (ro, lazy_build, isa => GroupList, handles => [qw(groups)]);

method _build_group_list { GroupList->new(src => $self->src) }
method _build_dag        { Graph->new(directed => 1) }

method graph {
    my $groups = $self->groups;

    # TODO
    # merge all the DAGs of the groups

#    say "Writing graph...";
#    my $w = Graph::Writer::Dot->new;
#    $w->write_graph($self->dag, 'SyntaxDag.dot');
#    say "...Done.";
}

1;

