#!perl

use Test::More tests => 2;
use Locale::Msgfmt;
use File::Spec;

sub slurp {
    open F, File::Spec->catfile(@_);
    my ($str, @str);
    @str = <F>;
    my $str = join "", @str;
    close F;
    return wantarray ? @str : $str;
}

my @all_bin = slurp("bin", "msgfmt.pl");
my @all_pm = slurp("lib", "Locale", "Msgfmt.pm");
my ($pm, $bin);
foreach(@all_bin) {
    $_ =~ /^use Locale::Msgfmt (.*);$/;
    $bin = $1 if($1);
}
foreach(@all_pm) {
    $_ =~ /^our \$VERSION = '(.*)';$/;
    $pm = $1 if($1);
}
is($pm, $Locale::Msgfmt::VERSION);
is($bin, $pm);
