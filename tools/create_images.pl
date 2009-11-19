#!/usr/bin/perl 
use strict;
use warnings;

# creating images for the web page displayng the translations

use GD;

my $width  = 302;
my $height = 22;

foreach my $p (0..100) {
	my $img = GD::Image->new($width, $height);
	my $white = $img->colorAllocate(255,255,255);
	my $black = $img->colorAllocate(0,0,0);
	my $blue  = $img->colorAllocate(0,0,255);
	my $red   = $img->colorAllocate(255,0,0);
	
	$img->rectangle(0,0,$width-1, $height-1, $black);
	
	if ($p) {
		$img->rectangle(2,2, 2+int(($width-6) * $p/100), $height-3, $blue);
		#$img->rectangle(0,0,99,99,$blue);
		$img->fill(3,3,$blue);
	}

	open my $fh, '>', "$p.png" or die;
	binmode $fh;
	print $fh $img->png;
}

