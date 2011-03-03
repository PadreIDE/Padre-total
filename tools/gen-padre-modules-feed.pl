#!/usr/bin/env perl

use strict;
use warnings;

use XML::Feed;
use URI;
use DateTime;

my $output = shift or die "Usage: $0 PATH_TO_OUTPUT_FILE (padre-cpan-uploads.rdf)\n";

my $cpan_feed = XML::Feed->parse( URI->new("http://search.cpan.org/uploads.rdf") );

my $padre_feed = XML::Feed->new( "RSS", version => "1.0" );

$padre_feed->title("Padre Uploads");
$padre_feed->link("http://padre.perlide.org/");
$padre_feed->self_link("http://padre.perlide.org/cpan-uploads.rdf");
$padre_feed->modified( DateTime->now );

foreach my $item ( $cpan_feed->items() ) {
	if ( $item->title() =~ m{\APadre-} ) {
		$padre_feed->add_entry($item);
	}
}

open my $out, ">", $output
	or die "Could not open ($output) $!";
binmode $out, ":utf8";
print {$out} $padre_feed->as_xml();
close($out);

