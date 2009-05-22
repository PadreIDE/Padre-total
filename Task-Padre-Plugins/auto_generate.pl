#!/usr/bin/perl

use strict;
use warnings;
use ORDB::CPANTS;
use YAML::LoadURI;
use Data::Dumper;

# Get 'Padre' Dist id
my $padre_dist = ORDB::CPANTS::Dist->select(
    'where dist=? LIMIT 1',
    'Padre'
);
my $id = $padre_dist->[0]->id;

# set feature dists
my @feature_dists = qw/
    Padre::Plugin::Parrot
    Padre::Plugin::Perl6
    Padre::Plugin::PSI
    Padre::Plugin::SpellCheck
    Padre::Plugin::SVN
    Padre::Plugin::SVK
    Padre::Plugin::Git
    Padre::Plugin::Catalyst
    Padre::Plugin::Mojolicious
/;

# get all used_by Padre, http://cpants.perl.org/dist/used_by/Padre
my %seen;
my $padre_prereq = ORDB::CPANTS::Prereq->select(
    'where in_dist=?',
    $id
);
foreach my $prereq ( @$padre_prereq ) {
    my $dist = ORDB::CPANTS::Dist->select(
        'where id = ?',
        $prereq->dist
    );
    my $dist_name = $dist->[0]->dist;
    if ( $dist_name =~ /^Padre-Plugin-/ ) {
        # no duplication
        next if $seen{$dist_name};
        $seen{$dist_name} = 1;
        
        # start real work
        my $module_name = $dist_name;
        $module_name =~ s/\-/\:\:/g; # Padre::Plugin::XX
        my ( $ver ) = ( $dist->[0]->vname =~ /\-([^\-]+)$/ );
        if ( grep { $_ eq $module_name } @feature_dists ) {
            my $meta = LoadURI("http://cpansearch.perl.org/dist/$dist_name/META.yml");
            print "feature '$meta->{abstract}',\n\t-default => 0,\n\t'$module_name' => '$ver';\n";
        } else {
            print "requires '$module_name' => '$ver';\n";
        }
    }
}

1;