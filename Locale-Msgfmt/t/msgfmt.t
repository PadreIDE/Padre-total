#!perl

use Test::More tests => 5;

use Locale::Msgfmt;
use File::Temp;
use File::Spec;

SKIP: {
    skip "Test needs Locale::Maketext::Gettext", 5 if(!eval("use Locale::Maketext::Gettext; 1;"));
    sub my_read_mo {
        my $str = "";
        my %h = read_mo(shift);
        foreach(sort keys %h){$str .= $_ . " " . $h{$_} . "\n";};
        return $str;
    }
    sub my_msgfmt {
        my ($fh, $filename) = File::Temp::tempfile();
        close $fh;
        my $in = shift;
        my $fuzzy = 0;
        if(shift) {
            $fuzzy = 1;
        }
        msgfmt({in => $in, out => $filename, fuzzy => $fuzzy});
        return $filename;
    }
    sub do_one_test {
        my $basename = shift;
        my $po = File::Spec->catfile("t", "samples", $basename . ".po");
        my $mo = File::Spec->catfile("t", "samples", $basename . ".mo");
        my $good = my_read_mo($mo);
        my $filename = my_msgfmt($po);
        my $test = my_read_mo($filename);
        is($test, $good);
        if($basename eq "basic") {
            unlink($filename);
            $filename = my_msgfmt($po, 1);
            $good = my_read_mo(File::Spec->catfile("t", "samples", "fuzz.mo"));
            $test = my_read_mo($filename);
            is($test, $good);
        }
        unlink($filename);
    }
    do_one_test("basic");
    do_one_test("fr-fr");
    do_one_test("context");
    do_one_test("ngettext");
}

