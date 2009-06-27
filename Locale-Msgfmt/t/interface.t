#!perl

use Test::More tests => 6;

use Locale::Msgfmt;
use File::Temp;
use File::Copy;
use File::Spec;

$dir = File::Temp::tempdir(CLEANUP => 1);
copy(File::Spec->catfile("t", "samples", "basic.po"), File::Spec->catfile($dir, "basic.po"));
msgfmt(File::Spec->catfile($dir, "basic.po"));
ok(-f File::Spec->catfile($dir, "basic.mo"));
unlink File::Spec->catfile($dir, "basic.mo");
msgfmt({in => File::Spec->catfile($dir, "basic.po")});
ok(-f File::Spec->catfile($dir, "basic.mo"));
unlink File::Spec->catfile($dir, "basic.mo");
msgfmt({in => File::Spec->catfile($dir, "basic.po"), out => File::Spec->catfile($dir, "mo")});
ok(-f File::Spec->catfile($dir, "mo"));
unlink(File::Spec->catfile($dir, "mo"));
mkdir(File::Spec->catdir($dir, "a"));
mkdir(File::Spec->catdir($dir, "b"));
move(File::Spec->catfile($dir, "basic.po"), File::Spec->catfile($dir, "a", "basic.po"));
msgfmt(File::Spec->catdir($dir, "a"));
ok(-f File::Spec->catfile($dir, "a", "basic.mo"));
unlink File::Spec->catfile($dir, "a", "basic.mo");
msgfmt({in => File::Spec->catdir($dir, "a")});
ok(-f File::Spec->catfile($dir, "a", "basic.mo"));
unlink File::Spec->catfile($dir, "a", "basic.mo");
msgfmt({in => File::Spec->catdir($dir, "a"), out => File::Spec->catdir($dir, "b"),});
ok(-f File::Spec->catfile($dir, "b", "basic.mo"));
