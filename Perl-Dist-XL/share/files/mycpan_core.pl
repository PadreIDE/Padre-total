
use strict;
use warnings;

use CPAN;
use FindBin qw($Bin);
my $cpan = "$Bin/../.cpan";
CPAN::HandleConfig->load(
  be_silent => 1,
);

$CPAN::Config = {
  'auto_commit' => q[1],
  'build_cache' => q[10],
  'build_dir' => qq[$cpan/build],
  'cache_metadata' => q[1],
  'commandnumber_in_prompt' => q[1],
  'cpan_home' => qq[$cpan],
  'dontload_hash' => {  },
  'ftp' => q[/usr/bin/ftp],
  'ftp_passive' => q[1],
  'ftp_proxy' => q[],
  'getcwd' => q[cwd],
  'gpg' => q[/usr/bin/gpg],
  'gzip' => q[/bin/gzip],
  'histfile' => qq[$cpan/histfile],
  'histsize' => q[100],
  'http_proxy' => q[],
  'inactivity_timeout' => q[0],
  'index_expire' => q[1],
  'inhibit_startup_message' => q[0],
  'keep_source_where' => qq[$cpan/sources],
  'lynx' => q[],
  'make' => q[/usr/bin/make],
  'make_arg' => q[],
  'make_install_arg' => q[],
  'make_install_make_command' => q[/usr/bin/make],
  'makepl_arg' => q[INSTALLDIRS=perl],
  'mbuild_arg' => q[],
  'mbuild_install_arg' => q[],
  'mbuild_install_build_command' => q[./Build],
  'mbuildpl_arg' => q[--installdirs core],
  'ncftp' => q[],
  'ncftpget' => q[],
  'no_proxy' => q[],
  'pager' => q[/usr/bin/less],
  'prerequisites_policy' => q[follow],
  'scan_cache' => q[atstart],
  'shell' => q[/bin/bash],
  'tar' => q[/bin/tar],
  'term_is_latin' => q[1],
  'term_ornaments' => q[1],
  'test_report' => q[0],
  'unzip' => q[/usr/bin/unzip],
  'urllist' => [q[http://cpan.strawberryperl.com/]],
  'use_sqlite' => q[0],
  'wget' => q[/usr/bin/wget],
};

#use Data::Dumper;
#print Dumper $CPAN::Config;

CPAN::Shell->install($ARGV[0]);
