package Padre::Pod::Indexer;

use strict;
use warnings;

our $VERSION = '0.13';

use File::Find::Rule;

# does not belong the to Wx namespace, it might be a stand alone module
# should collect
#    1) list of modules and pod files
#    2) index the pods (the head1 and head2 tags?)
#    3) index the pods - full text
#    3) find all subroutiones and list them

=pod

=head1 SYNOPIS

 my $indexer = Padre::Pod::Indexer->new;
 my @files = $indexer->list_all_files(@INC);

=cut

sub new {
    bless {}, $_[0];
}

sub list_all_files {
    my ($self, @dirs) = @_;

    my @files;
    foreach my $dir (@dirs) {
        my $len = length $dir;
        push @files, 
            map { $_ =~ s{/}{::}g; $_  } ## no critic
            map { $_ =~ s{^/}{};   $_  } ## no critic
            map { substr($_, $len, -3) }
            File::Find::Rule->name('*.pm')->file->in( $dir );
    }
    return @files;
}

1;
