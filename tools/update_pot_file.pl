#!/usr/bin/env perl
use strict;
use warnings;

# update messages.pot file with new strings detected.
#
use Cwd                   qw{ cwd };
use File::Spec::Functions qw{ catfile catdir };
use File::Find::Rule;

my $cwd       = cwd;
my $localedir = catdir ( $cwd, 'share', 'locale' );
unless(-d $localedir) {
	# Search for the 'locale' directory when 'share/locale'
	# directory is not found
	# and discard CVS/.svn/.git and blib folders
	my $rule = File::Find::Rule->new;
	$rule->or($rule->new->
		directory->name('CVS', '.svn', '.git', 'blib')->prune->discard,
		$rule->new);	
	my @files = $rule->name('locale')->in($cwd);
	if(scalar @files > 0) {
		$localedir = $files[0];
	} else {
		die "locale directory not found.\n";
	}
}

my $pot_file  = catfile( $localedir, 'messages.pot' );
my $pmfiles   = catfile( $cwd, 'files.txt' );

# build list of perl modules from where to extract strings
my @pmfiles = grep {/^lib/}
	File::Find::Rule->file()->name("*.pm")->relative->in($cwd);
open my $fh, '>', $pmfiles or die "cannot open '$pmfiles': $!\n";
print $fh map { "$_$/" } @pmfiles;
close $fh;

unlink $pot_file;
my ($gettext) = grep {$_ =~ /^xgettext/} qx{xgettext -V};
chomp $gettext;
if ($gettext ne 'xgettext (GNU gettext-tools) 0.17') {
	die "Due to bug #1132 we only allow the use of v0.17 of xgettext\n";
}

system("xgettext",  "--keyword=_T",  "--from-code=utf-8", "-o", $pot_file, "-f", $pmfiles, "--sort-output") == 0
	or die "xgettext exited with return code " . ($? >> 8);

# cleanup
unlink $pmfiles;
