#!/usr/bin/perl
use strict;
use warnings;

use Cwd                   qw{ cwd };
use File::Spec::Functions qw{ catfile catdir };
use File::Find::Rule;
use File::Basename        qw{ basename };

my $cwd       = cwd;
my $localedir = catdir ( $cwd, 'share', 'locale' );
my $pot_file  = catfile( $localedir, 'messages.pot' );

chdir $localedir;
my @po_files  = glob '*.po';

my $header  = "Generated by $0 on " . localtime() . "\n\n";
$header    .= "Language  Errors\n";
my $report = '';
foreach my $po_file (@po_files) {
	system "LANG=C msgcmp $po_file messages.pot 2> err";
	$report .= "\n------------------\n";
	$report .= basename($po_file) . "\n\n";
	$header .= basename($po_file) . "     ";
	if (open my $fh, '<', 'err') {
		local $/ = undef;
		my $data = <$fh>;
		if ($data =~ /msgcmp: found (\d+) fatal errors?/) {
			$report .= "Fatal errors: $1\n\n";
			$header .= $1;
		}
		$report .= $data;
	}
	$header .= "\n";
	unlink 'err';
}
chdir $cwd;

open my $fh, '>', 'po_report.txt' or die;
print {$fh} $header;
print {$fh} $report;
