#!perl
use strict;
use warnings;
use Data::Dumper;
use Template;
use JSON;


my $config = {
		INCLUDE_PATH => 'tt',  # or list ref
		POST_CHOMP   => 1,               # cleanup whitespace 
		EVAL_PERL    => 0,               # evaluate Perl code blocks
		OUTPUT_PATH   => 'documentroot',
};
my $tt = Template->new($config);
my $stash = do 'build/data.perl';
my $pages_dir = 'tt/pages';
my $page_handle;
opendir( $page_handle, $pages_dir) 
	|| die "Failed to opendir '$pages_dir' , $!";
while ( my $file = readdir( $page_handle ) ) {
	next unless $file =~ /\.(html)$/;
	warn $file;
	$tt->process('about.html' , $stash,  'about.html' )
		|| die $tt->error();
}