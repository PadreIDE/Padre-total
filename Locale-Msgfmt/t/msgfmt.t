#!perl

use Test::More tests => 1;

use Locale::Msgfmt;
use File::Spec;
use File::Basename;
use File::Temp;

SKIP: {
    eval("use Locale::Maketext::Gettext; 1;");
    skip "Test needs Locale::Maketext::Gettext", 1 if($@);
    my $dump_mo = File::Spec->catfile(dirname($0), "..", "dev", "dump-mo");
    my %h;
    my $good = "";
    %h = read_mo("t/samples/fr-fr.mo");
    foreach(sort keys %h){$good .= $_ . " " . $h{$_} . "\n";};
    ($fh, $filename) = File::Temp::tempfile();
    close $fh;
    msgfmt({in => "t/samples/fr-fr.po", out => $filename});
    my $test = "";
    %h = read_mo($filename);
    foreach(sort keys %h){$test .= $_ . " " . $h{$_} . "\n";};
    is($test, $good);
}

