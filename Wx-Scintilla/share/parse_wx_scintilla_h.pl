use strict;
use warnings;

my $filename = 'wx-scintilla/include/WxScintilla.h';
if(open my $fh, $filename) {
	print "use constant {\n";
	while(my $line = <$fh>) {
		if($line =~ /^\s*#define\s+(wxSTC_.+)\s+(.+)\s*$/) {
			my ($name, $val) = ("$1", $2);
			print "$name => $val,\n";
		}
	}
	print "};\n";
	close $fh;
} else {
	die "Cannot open $filename\n";
}