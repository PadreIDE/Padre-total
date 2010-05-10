package Vimper::CommandSheet;

use 5.010;
use List::MoreUtils qw(zip);
use IO::All;
use Moose;
use Moose::Autobox;
use MooseX::Method::Signatures;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(Str ArrayRef HashRef);
use aliased 'Vimper::Command::Normal' => 'NormalCommand';
use Vimper::Command::Normal::Motion;

# a model of a tsv spreadsheet where each row is a VIM command

has file     => (ro, required  , isa => Str);
has data     => (ro, lazy_build, isa => ArrayRef[HashRef[Str]]);
has commands => (ro, lazy_build, isa => ArrayRef[NormalCommand]);

method _build_data {
    my $file = $self->file;
    my $lines = [io($file)->slurp]->map(sub{chomp; $_});
    my ($head, $tail) = ($lines->shift, $lines);
    my @head = map { s/\?//; $_ } split /\t/, $head;
    return $tail->map(sub{
        my @v = map { s/^\s+//; s/\s+$//; $_ } split /\t/;
        return {zip @head, @v};
    });
}

method _build_commands { $self->data->map(sub{ $self->_build_command($_) }) }

method _build_command(HashRef $data) { $self->command_class->new(%$data) }

method syntax_paths { $self->commands->map(sub{ $_->get_syntax_paths }) }    

# e.g. for file "normal motion" return the command class
# Vimper::Command::Normal::Motion
method command_class {
    (my $f = $self->file) =~ s/\.tsv//;
    'Vimper::Command::'.
    $f->split('_')
      ->map(sub{ ucfirst })
      ->join('::');
}

1;
