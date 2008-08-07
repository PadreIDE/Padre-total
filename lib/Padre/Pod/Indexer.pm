package Padre::Pod::Indexer;
use strict;
use warnings;

our $VERSION = '0.01';

use File::Find::Rule;

# does not belong the to Wx namespace, it might be a stand alone module
# should collect
#    1) list of modules and pod files
#    2) index the pods (the head1 and head2 tags?)
#    3) index the pods - full text
#    3) find all subroutiones and list them


=head1 SYNOPIS

 my $indexer = Padre::Pod::Indexer->new;
 my @files = $indexer->list_all_files(@INC);

=cut

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    return $self;
}

sub list_all_files {
    my ($self, @dirs) = @_;

    my @files;
    foreach my $d (@dirs) {
        my $l = length $d;
        push @files, 
                map {$_ =~ s{/}{::}g; $_}
                map {$_ =~ s{^/}{}; $_}
                map {substr($_, $l, -3)} File::Find::Rule->file()
                        ->name( '*.pm' )
                        ->in( $d );
    }
    return @files;
}


1;


