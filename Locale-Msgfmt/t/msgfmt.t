#!perl

use Test::More tests => 3;

use Locale::Msgfmt;
use File::Temp;

SKIP: {
    skip "Test needs Locale::Maketext::Gettext", 1 if(!eval("use Locale::Maketext::Gettext; 1;"));
    sub my_read_mo {
        my $str = "";
        my %h = read_mo(shift);
        foreach(sort keys %h){$str .= $_ . " " . $h{$_} . "\n";};
        return $str;
    }
    sub my_msgfmt {
        my ($fh, $filename) = File::Temp::tempfile();
        close $fh;
        msgfmt({in => shift, out => $filename});
        return $filename;
    }
    sub do_one_test {
        my $basename = shift;
        my $po = "t/samples/" . $basename . ".po";
        my $mo = "t/samples/" . $basename . ".mo";
        my $good = my_read_mo($mo);
        my $filename = my_msgfmt($po);
        my $test = my_read_mo($filename);
        is($test, $good);
        unlink($filename);
    }
    do_one_test("fr-fr");
    do_one_test("context");
  TODO: {
      local $TODO = "not yet implemented";
      
      do_one_test("ngettext");
    }
}

