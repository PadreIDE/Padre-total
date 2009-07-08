#!perl
use strict;
use warnings;
use Template;
use File::Spec;


my $config = {
		INCLUDE_PATH => 'tt',  # or list ref
		POST_CHOMP   => 1,               # cleanup whitespace 
		EVAL_PERL    => 0,               # evaluate Perl code blocks
		OUTPUT_PATH   => 'documentroot',
};
my $tt = Template->new($config);
# yank in the global site data - FIXME somebody json or yaml'ify this pls
my $stash = do 'build/data.perl';

# for now - only a flat directory processed w/ template.
my $pages_dir = 'tt/pages';
my $page_handle;
opendir( $page_handle, $pages_dir) 
	|| die "Failed to opendir '$pages_dir' , $!";
while ( my $file = readdir( $page_handle ) ) {
	next unless $file =~ /\.(html)$/; 
	
	my $template = File::Spec->catfile( $pages_dir, $file );
	$template =~ s|^tt/||;
	# OUTPUT_PATH is appended to $file by TT
	$tt->process($template , $stash,  $file )
		|| die $tt->error();
}

symlink( '../static' , 'documentroot/static' );