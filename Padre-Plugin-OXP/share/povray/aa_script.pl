#!/usr/bin/perl
use strict;
use warnings;
use Text::CSV;
use File::Temp;
use Digest::JHash 'jhash';
use Data::Dumper;

my $max = 1 << 31;
$max*=2;
my $n_planets = 8 * 256;

my $galaxy_csv = shift @ARGV;
my $render = shift @ARGV;
my $clobber = shift @ARGV;

my $POV_template = <<POV;
#version unofficial megapov 1.21;
#include "cm_camera.inc"
#include "pp_textures.inc"
#include "pp_gas.inc"
#include "pp_continental.inc"

#debug  "%s" 

#declare Radius = 1;


        %s(     Radius
                %d,  // colour
                %d,  // pattern
                %d,  // galaxy X
                %d,  // galaxy Y
                %f // float modifier 1
                %f // float modifier 2
        )

light_source { -0.15 color rgb 1 
 /* area_light <0.05,0,0> <0,0,0.05> 3,3 
  adaptive 1
  circular
  jitter */
}

///*
camera { 
    CubeCamera( frame_number ,Radius,0)
}
//*/


POV


my $csv = Text::CSV->new;
open( my $fh , $galaxy_csv ) or die $!;
my $headings = $csv->getline($fh);
#die Dumper $headings;

while ( my $row = $csv->getline($fh) ) {
        my %info;
        @info{@$headings} = @$row;
        
        my $seed = jhash $info{Name};
        my $seed2= jhash scalar reverse $info{Name};
        my $norm_seed = $seed/$max; # normalised to 0..1
        my $norm_seed2= $seed2/$max; 
        my $galaxy_X = $info{X};
        $galaxy_X =~ s/[^\d]//g;
        my $galaxy_Y = $info{Y};
        $galaxy_Y =~ s/[^\d]//g;
        my $planet_type = $seed % $n_planets+1;
        my $planet_specifier = $seed % int(sqrt($n_planets+1));

        # Barren/rocky , Gas Giant , Continental , Artificial
        my $formation_seed = $seed % 11;
        my %formations = (
                0 => 'Rocky' ,               
                1 => 'Rocky',
                2 => 'Continental',

                3 => 'Continental' , 
                4 => 'Rocky',
                5 => 'Continental',

                6 => 'Gas' ,                
                7 => 'Rocky',
                8 => 'Continental',

                9 => 'Continental' ,                
                10=> 'Rocky',
               # 2 => 'Continental',
               # 3 => 'Artificial'
        );

        # Choose a colour map as $Formation + $colour_seed
        my $colour_seed = $seed2 % 13;

        # Choose a pattern based on 
        my $pattern_seed= $seed % 8;

        my $macro = $formations{$formation_seed};


        
        my $pov_sdl = sprintf $POV_template, $info{Name},
                $macro,
                $colour_seed, $pattern_seed,
                $galaxy_X, $galaxy_Y,
                $norm_seed, $norm_seed2;
        
        #my $tf = File::Temp->new;
        #$tf->print( $pov_sdl );
        #$tf->close;
        my $sdl_file = 'SDL/' . $info{Name} . '.pov';
        open( my $sdl_fh , '>' , $sdl_file ) or die $!;
        $sdl_fh->print( $pov_sdl );
        $sdl_fh->close;
        
        
        if ( defined $render ) {
                if ($render ne '1') {
                        next unless $render eq $macro;
                }
                print $info{Name},$/;
                my $output = 'Textures/'. $info{Name}.'.png';
                if ( -f $output and !$clobber ) {
                        warn 'noclobber - skipping ' . $output;
                        next;
                }
                my $rc = system(
                        'megapov',
                        '+Lcm',
                        '-V',
                        '+A0.05','+AM3',
                        #'-D',
                        '+KFI0','+KFF5',
                        #'+W256', '+H256', # medium resolution
                        '+W512', '+H512', # high resolution
                        
                        '+Ocubestitch..png',
                        '+I'.$sdl_file,
                );
               # sleep 10; # Quasi thermal control
                
                die $! unless $rc==0;
                cubestitch( 'cubestitch.%d.png' );
                rename 'output.png', $output;
                die $pov_sdl unless -f $output;
        }
        
        else { print $pov_sdl }
        
}


use Imager;
use Imager::File::PNG;

sub cubestitch {

        my $name = shift;
        my @files ;
        for my $i (0..5) {
                my $fname = sprintf $name , $i;
                die "Missing frame $i" unless -f $fname;
                push @files, $fname;
        }


        my $temp = new Imager;
        $temp->read( file=>$files[0] ) or die $temp->errstr;

warn my $x =$temp->getwidth;
warn my $y =$temp->getheight;

        die "Image not square ($x,$y)" unless $x==$y;

        my $out = new Imager xsize=>$x, ysize=>$y*6;

        # splat each tile onto a cube map size canvas
        for my $i (0..5) {
                my $side = new Imager;
                $side->read(file => $files[$i]) or die $side->errstr;
                $side->flip(dir=>'h');
                $out->compose(src=>$side, tx=>0,ty=>$i*$y   );
               
        }

        $out->write( file=>'output.png' ) or die $out->errstr;
}
