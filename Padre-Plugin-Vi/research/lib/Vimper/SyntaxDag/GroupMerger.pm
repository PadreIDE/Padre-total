package Vimper::SyntaxDag::GroupMerger;

use 5.010;
use Moose;
use Moose::Autobox;
use MooseX::Method::Signatures;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(HashRef);
use Graph;
use aliased 'Vimper::SyntaxDag::Group';

# a command object with 1 public method: merge
# merges a group of VIM normal motion commands with the same syntax DAG
# into one huge DAG

has registry   => (ro, required, isa => HashRef);
has group      => (ro, required, isa => Group  , handles => {map { ("grp_$_" => $_) }
                                                             qw(name
                                                                predecessors
                                                                vertices
                                                                get_label
                                                                get_path_node
                                                                syntax_group
                                                                key1_node_kind
                                                                count_node_kind)});
has dag        => (ro, required, isa => 'Graph', handles => [qw(has_vertex
                                                                add_vertex
                                                                add_edge
                                                                set_label)]);

my $type;

# only allowed entry point 
method merge {
    $self->registry->{by_type}  ||= {};
    $self->registry->{by_group} ||= {};
    for ($self->grp_vertices) { $type = $_; $self->merge_or_add_node };
    for ($self->grp_vertices) { $type = $_; $self->merge_node_edges };
}

method merge_or_add_node {
    my $merge_into;
    if ($self->has_node_of_type && ($merge_into = $self->can_merge_node))
        { $self->register_node($merge_into) }
    else
        { $self->add_node }
}

method merge_node_edges {
    for my $pred_type ($self->grp_predecessors($type)) {
        $self->add_edge(
            $self->get_name_of_type($pred_type),
            $self->get_name_of_type($type),
        );
    }
}

method add_node {
    my $name  = $self->register_node(0);
    my $label = $self->compute_node_label($name);
    $self->add_vertex($name);
    $self->set_label($name, $label);
}

method can_merge_node {
    my $path_node = $self->grp_get_path_node($type);
    return 1 if $path_node->must_merge;
    return 0 if $path_node->must_not_merge;

    # count nodes can be merged, only if correct kind already exists
    # key nodes can be merged, if key-1 is "g", and correct kind exists

    my $name = $path_node->graph_name;
    return
        $name eq 'count'? $self->find_count_node_for_group:
        $name eq 'key1' ?
            $path_node->key eq 'g'? $self->find_key1_node_for_group:
            $path_node->key eq 'm'? $self->find_key1_node_for_group:
            0: 0;
}

method register_node(Str $merge_into) {
    my $nodes_by_type = $self->get_nodes_of_type;
    my $name = "$type-". (scalar $nodes_by_type->flatten + 1);
    $nodes_by_type->push({
        group => $self->group,
        name  => $name,
    });
    my $nodes_of_group = $self->get_nodes_of_group->{ $self->grp_syntax_group } ||= {};
    my $graph_name = $self->grp_get_path_node($type)->graph_name;
    $nodes_of_group->{$type} = 
        !$merge_into          ? $name:
        $graph_name eq 'count'? $merge_into:
        $graph_name eq 'key1' ? $merge_into:
                                "$type-1";
    return $name;
}

method find_count_node_for_group { $self->find_some_node_for_group('count_node_kind') }
method find_key1_node_for_group  { $self->find_some_node_for_group('key1_node_kind') }

method find_some_node_for_group(Str $accessor) {
    my $grp_accessor = "grp_$accessor";
    my $kind = $self->$grp_accessor;
    my @recs = $self->get_nodes_of_type
                    ->grep(sub{ $kind eq $_->{group}->$accessor })
                    ->flatten;
    return @recs? $recs[0]->{name}: 0;
}

method   has_node_of_type { exists $self->registry->{by_type}->{$type} }
method  get_nodes_of_type { $self->registry->{by_type}->{$type} ||= [] }
method get_nodes_of_group { $self->registry->{by_group} }
method compute_node_label { $self->grp_get_label($type) } # pop(). "=". 
method   get_name_of_type { $self->get_nodes_of_group->{$self->grp_syntax_group}->{ pop() } }

1;

__END__
