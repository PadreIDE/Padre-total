package Vimper::SyntaxDag;

use 5.010;
use Moose;
use Moose::Autobox;
use MooseX::Method::Signatures;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(HashRef);
use Graph;
use Graph::Writer::Dot;
use Vimper::GraphUtil;
use aliased 'Vimper::CommandSheet';
use aliased 'Vimper::SyntaxDag::GroupList';
use aliased 'Vimper::SyntaxDag::Group';
use aliased 'Vimper::SyntaxDag::GroupMerger';

has src        => (ro, required  , isa => CommandSheet);
has group_list => (ro, lazy_build, isa => GroupList, handles => [qw(groups)]);
has dag        => (ro, lazy_build, isa => 'Graph');
has registry   => (ro, required  , isa => HashRef, default => sub { {} });

method _build_group_list { GroupList->new(src => $self->src) }
method _build_dag        { Graph->new(directed => 1) }

method graph {

    # graph each group by itself:
    # $_->graph for $self->groups->flatten;

    $self->add_group($_) for $self->groups->flatten;

    use Data::Dumper;print Dumper $self->dag;exit;

    my $name = 'all_groups.dot';
    my $w = Graph::Writer::Dot->new;
    $w->write_graph($self->dag, $name);
    system("'/c/Program Files/Graphviz2.26.3/bin/dot.exe' -Tpng -O $name")
        && die "Can't graphviz";
}

method add_group(Group $group) {
    GroupMerger->new(dag      => $self->dag,
                     group    => $group,
                     registry => $self->registry)
               ->merge;
}

1;

