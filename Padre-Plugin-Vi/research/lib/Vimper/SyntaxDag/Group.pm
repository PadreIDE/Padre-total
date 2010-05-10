package Vimper::SyntaxDag::Group;

use 5.010;
use Moose;
use Moose::Autobox;
use MooseX::Method::Signatures;
use MooseX::Has::Sugar;
use Graph;
use Graph::Writer::Dot;
use MooseX::Types::Moose qw(HashRef ArrayRef Str);
use aliased 'Vimper::CommandSheet';
use aliased 'Vimper::Command::Normal' => 'NormalCommand';
use aliased 'Vimper::SyntaxPath';

# two commands are in the same syntax group if they have the same
# syntax paths- e.g. "h" and "j" are in the same group, but "f" is
# in a different group
# all commands in a group have the same DAG, and this class models
# that DAG
# we build the graph of the group by adding all the possible syntax
# paths of all commands in the group to the graph
# the resulting DAG could be used for many wonderful things

has name   => (ro, required  , isa => Str);
has src    => (ro, required  , isa => ArrayRef[NormalCommand]);
has dag    => (ro, lazy_build, isa => 'Graph');

method _build_dag { Graph->new(directed => 1) }

my $IDX = 0;

method BUILD {
    say "Building DAG for group ". $self->name;
    $self->add_command($_) for $self->src->flatten;

    my $name = 'dot_out/'. ($IDX++). '.dot';
    my $w = Graph::Writer::Dot->new;
    $w->write_graph($self->dag, $name);
#     system("'/c/Program Files/Graphviz2.26.3/bin/dot.exe' -Tpng -O $name")
#         && die "Can't graphviz";
}

method add_command(NormalCommand $command) {
    say "Adding command to group ". $command->to_string;
    $self->add_path($_) for $command->syntax_paths->flatten;
}

method add_path(SyntaxPath $path) {
    my $g = $self->dag;
    my $group_name = $self->name;
    my ($node, $prev_path_node);
    for my $path_node ($path->parts->flatten) {

        my $node      = escape($path_node->graph_name);
        my $label     = escape($path_node->graph_label);
        my $bag_key   = $path_node->bag_key;
        my $label_sep = $path_node->label_sep;

        if (!$g->has_vertex($node)) {
            $g->add_vertex($node);
            $self->set_label($node, $label);
            $g->set_vertex_attribute($node, path_node => $path_node);
            $self->init_bag($node, $bag_key => $label) if $bag_key;
        } else {
            $self->append_to_label($node, "$label_sep$label")
                if $bag_key
                && $self->add_to_bag($node, $bag_key, $label);
        }

        $g->add_edge($prev_path_node, $node) if
            $prev_path_node
            && !$g->has_edge($prev_path_node, $node);

        $prev_path_node = $node;
    }
}

method append_to_label(Str $node, Str $new_text) {
    my $g = $self->dag;
    my $old = $g->get_vertex_attribute($node, 'label');
    $self->set_label($node, "$old$new_text");
}

method set_label (Str $node, Str $text) {
    my $g = $self->dag;
    $g->set_vertex_attribute($node, label => $text);
}

method init_keys (Str $node, Str $key)
    { $self->init_bag($node, vimperKeys => $key) }

method init_commands (Str $node, Str $command_str)
    { $self->init_bag($node, vimperCommands => $command_str) }

method init_bag (Str $node, Str $name, Str $key) {
    my $g = $self->dag;
    $g->set_vertex_attribute($node, $name, {$key => 1});
}

method add_to_bag(Str $node, Str $name, Str $key) {
    my $g = $self->dag;
    my $existing= $g->get_vertex_attribute($node, $name);
    if (!exists $existing->{$key}) {
        $existing->{$key} = 1;
        return 1;
    }
    return 0;
}

sub escape {
    my $s = shift;
    $s =~ s/"/\\"/g;
    return $s;
}

1;

