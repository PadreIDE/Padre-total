package Vimper::SyntaxDag::GroupList;

use 5.010;
use Moose;
use Moose::Autobox;
use MooseX::Method::Signatures;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(ArrayRef);
use aliased 'Vimper::CommandSheet';
use aliased 'Vimper::SyntaxDag::Group';

# a list of groups of commands built from a commandsheet

has src    => (ro, required  , isa => CommandSheet, handles => [qw(commands)]);
has groups => (ro, lazy_build, isa => ArrayRef[Group]);

method _build_groups {
    my (%groups, @groups);
    for my $command ($self->commands->flatten)
        { push @{ $groups{$command->syntax_group} ||= [] }, $command }
    for my $group_name (keys %groups) {
        push @groups, Group->new
            (name => $group_name, src => $groups{$group_name});
    }
    return \@groups;
}

1;
