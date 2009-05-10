#!/usr/bin/perl
use strict;
use warnings;

use Cwd                   qw{ cwd };
use File::Spec::Functions qw{ catfile catdir };
use File::Find::Rule;
use File::Basename        qw{ basename };
use File::Temp            qw{ tempdir };
use Data::Dumper          qw{ Dumper };
use Env                   qw{ LANG };
use Getopt::Long          qw{ GetOptions };
#use Locale::PO;

my %reports;

my $text;
my $html;
my $dir;
my $project_dir;
my $details;
my $all;
my $trunk;
GetOptions(
	'text'      => \$text, 
	'html'      => \$html, 
	'dir=s'     => \$dir, 
	'project=s' => \$project_dir,
	'details'   => \$details,
	'all'       => \$all,
	'trunk=s'   => \$trunk,
	) or usage();
usage() if not $text and not $html;

$LANG = 'C';

my $tempdir = tempdir( CLEANUP => 1 );
my $cwd       = cwd;

usage("--all and --project are mutually exclusive") 
	if $all and $project_dir;
if (not $all and not $project_dir) {
	$project_dir = $cwd;
}


if ($project_dir) {
	$reports{basename $project_dir} = collect_report($project_dir);
} elsif ($all) {
	$trunk ||= $cwd;
	foreach my $project_dir ("$trunk/Padre", glob( "$trunk/Padre-Plugin-*" )) {
		#print "P: $project_dir\n";
		$reports{basename $project_dir} = collect_report($project_dir);
	}
}
	
my $text_report_file = catfile($cwd, 'po_report.txt');

if ($text) {
	save_text_report($text_report_file);
} 
if ($html) {
	usage("--dir was missing") if not $dir;
	usage("--dir $dir does not exist") if not -d $dir;

	save_html_report($dir);
}
exit 0;



sub collect_report {
	my ($project_dir) = @_;

	my %data;
	my $plugin_name = basename $project_dir;
	$plugin_name =~ s/.*-//;

	my $share = catdir ( $project_dir, 'share' );
	if (not -e $share) {
		($share) = File::Find::Rule->directory()->name('share')->in(catdir( $project_dir, 'lib'));
	}
	if (not $share or not -e $share) {
		warn("Could not find a 'share' directory in '$project_dir'");
		return;
	}

	my $localedir = catdir ( $share, 'locale' );

	if (not -d $localedir) {
		warn("Can't find locale directory '$localedir'.");
		return;
	}


	my @po_files  = glob "$localedir/*.po";
	my $pot_file  = catfile( $localedir, 'messages.pot' );
	if (open my $fh, '<', $pot_file) {
		while (my $line = <$fh>) {
			if ($line =~ /^msgid/) {
				$data{total}++;
			}
		}
	}
	
	foreach my $po_file (sort @po_files) {
		#print "$po_file\n";
		my $err = "$tempdir/err";
		system "msgcmp $po_file $pot_file 2> $err";
		my $language = substr(basename($po_file), 0, -3);
		if ($plugin_name ne 'Padre') {
			$language =~ s/^$plugin_name-//;
		}
		if (open my $fh, '<', $err) {
			local $/ = undef;
			$data{$language}{details} = <$fh>;
			if ($data{$language}{details} =~ /msgcmp: found (\d+) fatal errors?/) {
				$data{$language}{errors} = $1;
			} else {
				$data{$language}{errors} = 0;
			}
		} else {
			# TODO: report that could not open file
		}
	}
	return \%data;
}

sub save_html_report {
	my ($dir) = @_;
	my $html = "<html><head><title>Padre translation status report</title></head><body>\n";
	$html .= <<'END_CSS';
<style type="text/css">
.red {
    background-color: red;
}
.yellow {
    background-color: yellow;
}
.green {
    background-color: lightgreen;
}
</style>
END_CSS

	$html .= "<h1>Padre translation status report</h1>\n";
	$html .= "<p>The numbers showing the number of errors. na means that translation does not exist at all</p>\n";
	$html .= "<p>Generated on: " . localtime() . "</p>\n";
	$html .= "<table border=1>\n";

#die Dumper $reports{"Padre-Plugin-SpellCheck"};

	my @languages = sort grep {!/total/} keys %{$reports{Padre}};
	$html .= _header(@languages);
	
	my %totals;
	
	foreach my $project (sort keys %reports) {
		$html .= "<tr><td>$project</td><td>";
		my $total = $reports{$project}{total};
		$html .= defined  $total ? $total : 'na';
		$total ||= 0;

		$html .= "</td>";
		if ($reports{$project}{total}) {
			$totals{total} += $reports{$project}{total};
		}
		foreach my $language (@languages) {
			if ($reports{$project}{total}) {
				if (defined $reports{$project}{$language}{errors}) {
					$html .= _td_open($reports{$project}{$language}{errors}, $total);
					$html .= $reports{$project}{$language}{errors};
					$totals{$language} += $reports{$project}{$language}{errors};
				} else {
					#$html .= '<td class=red>-';
					$html .= "<td class=red>$reports{$project}{total}";
					$totals{$language} += $reports{$project}{total};
				}
			} else {
				$html .= '<td>na';
			}
			$html .= '</td>';
		}
		$html .= "</tr>\n";
	}
	$html .= "<tr><td>TOTAL</td><td>$totals{total}</td>";
	foreach my $language (@languages) {
		$html .= _td_open($totals{$language}, $totals{total});
		$html .= $totals{$language};
		$html .= "</td>";
	}
	$html .= "</tr>";
	
	$html .= _header(@languages);
	
	$html .= "</table>\n";
	$html .= "</body></html>";
	open my $fh, '>', "$dir/index.html" or die;
	print $fh $html;
}

sub _header {
	return "<tr><td>Project</td><td>Total</td>" . (join "", map {"<td>$_</td>"} @_) . "</tr>\n";
}

sub _td_open {
	my ($errors, $total) = @_;
	if ( $errors > $total / 20  ) {
		return q(<td class=red>);
	} elsif ( $errors > 0 ) {
		return q(<td class=yellow>);
	} else {
		return q(<td class=green>);
	}
}

sub save_text_report {
	my ($text_report_file) = @_;
	open my $fh, '>', $text_report_file or die;
	
	print $fh "Generated by $0 on " . localtime() . "\n\n";
	
	
	foreach my $project (sort keys %reports) {
		print $fh "--------------------\n";
		print $fh "Project $project\n\n";
		print $fh generate_text_report($reports{$project});
	}
	print "file $text_report_file generated.\n";
}

sub generate_text_report {
	my ($data) = @_;

	my $report    .= "Language  Errors\n";
	foreach my $language (sort keys %$data) {
		$report .= sprintf("%-10s %s\n", $language, $data->{$language}{errors});
	}
	
	if ($details) {
		foreach my $language (sort keys %$data) {
			$report .= "\n------------------\n";
			$report .= $language . "\n\n";
			if ($data->{$language}{errors}) {
				$report .= "Fatal errors: $data->{$language}{errors}\n\n";
			}
			$report .= $data->{$language}{details};
		}
		
	}
	return $report;
}



sub usage {
	my $msg = shift;
	print "$msg\n\n" if defined $msg;
	print <<"END_USAGE";
Usage: $0
        --text 
	--details
        --html --dir DIR

	--project         path to the project directory
	--all             all the projects
	--trunk  PATH     to root of all the projects
	
        --all and --project are mutually exclusive
END_USAGE

	exit 1;
}

