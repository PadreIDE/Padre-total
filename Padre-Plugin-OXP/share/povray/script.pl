#!/usr/bin/perl
use strict;
use warnings;


use Digest::JHash 'jhash';

my $max = 1 << 31;
$max*=2;
my $seed = jhash rand();
my $norm_seed = $seed/$max; # normalised to 0..1
my $n_planets = 8 * 256;

my $planet_type = $seed % $n_planets+1;
my $planet_specifier = $seed % int(sqrt($n_planets+1));

# Barren/rocky , Gas Giant , Continental , Artificial
my $formation_seed = $planet_type % 4;
my %formations = (
        0 => 'Rocky',
        1 => 'Gas' ,
        2 => 'Continental',
        3 => 'Artificial'
);

# Choose a colour map as $Formation + $colour_seed
my $colour_seed = $planet_type % 11;

# Choose a pattern based on 
my $pattern_seed= $planet_specifier % 5;



print "planet type $planet_type, $planet_specifier",$/;

my $macro = $formations{$formation_seed};

my $POV_template = <<POV;
#version unofficial megapov 1.21
#include "cm_camera.inc"

#declare Radius = 1;

sphere { <0,0,0> Radius
        hollow no_shadow inverse double_illuminate
        material {
                $macro($colour_seed,$pattern_seed)
        }
}
CubeMapBoxes(Radius)
CubeLight(4,Radius)
CubeMapCamera()

POV

print $POV_template;