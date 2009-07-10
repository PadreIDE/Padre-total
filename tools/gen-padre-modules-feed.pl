#!/usr/bin/perl

use strict;
use warnings;

use XML::Feed;
use URI;
use DateTime;

my $cpan_feed =
    XML::Feed->parse(URI->new("http://search.cpan.org/uploads.rdf"))
    ;

my $padre_feed = XML::Feed->new("RSS", version => "1.0");

$padre_feed->title("Padre Uploads");
$padre_feed->link("http://padre.perlide.org/");
$padre_feed->self_link("http://padre.perlide.org/cpan-uploads.rdf");
$padre_feed->modified(DateTime->now);

foreach my $item ($cpan_feed->items())
{
    if ($item->title() =~ m{\APadre-})
    {
        $padre_feed->add_entry($item);
    }
}

open my $out, ">", "padre-cpan-uploads.rdf"
    or die "Could not open padre-cpan-uploads.rdf";
binmode $out, ":utf8";
print {$out} $padre_feed->as_xml();
close($out);

