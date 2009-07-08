#!perl
use strict;
use warnings;
use Template;
use File::Spec;
use File::Copy qw(copy);
use File::Find::Rule;
use File::Basename qw(dirname basename);
use YAML::Tiny qw(LoadFile);

my ($source_dir, $output_dir) = @ARGV;
die "No output dir  Usage: $0 SOURCE_DIR OUTPUT_DIR\n" if not $output_dir or not -d $output_dir;

# copy static files
for my $file (File::Find::Rule->relative->file()->in("$source_dir/documentroot")) {
	next if $file =~ m{.svn};
	my $dir = "$output_dir/" . dirname($file);
	mkdir ($dir);
	my $to = "$dir/" . basename($file);
	copy("$source_dir/documentroot/$file", $to);
	chmod 0644, $to;
}

my $config = {
		INCLUDE_PATH => "$source_dir/tt",  # or list ref
		POST_CHOMP   => 1,               # cleanup whitespace 
		EVAL_PERL    => 0,               # evaluate Perl code blocks
		OUTPUT_PATH   => $output_dir,
};

my $tt = Template->new($config);
my $stash = LoadFile("$source_dir/data/stash.yml");

# for now - only a flat directory processed w/ template.
my $pages_dir = "$source_dir/tt/pages";
my $page_handle;
opendir( $page_handle, $pages_dir) 
	|| die "Failed to opendir '$pages_dir' , $!";
while ( my $file = readdir( $page_handle ) ) {
	next unless $file =~ /\.(html)$/; 
	
	my $template = File::Spec->catfile( 'pages', $file );
	# OUTPUT_PATH is appended to $file by TT
	$tt->process($template , $stash, $file )
		|| die $tt->error();
}

