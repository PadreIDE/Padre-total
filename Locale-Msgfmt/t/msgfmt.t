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
    my $good = `perl "$dump_mo" t/samples/fr-fr.mo`;
    ($fh, $filename) = File::Temp::tempfile();
    close $fh;
    msgfmt({in => "t/samples/fr-fr.po", out => $filename});
    my $test = `perl "$dump_mo" "$filename"`;
    is($test, $good);
}

