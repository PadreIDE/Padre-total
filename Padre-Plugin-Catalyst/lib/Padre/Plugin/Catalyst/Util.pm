package Padre::Plugin::Catalyst::Util;
# some code used all around the Plugin
use Cwd ();
use File::Spec ();

our $VERSION = '0.05';

# get the Catalyst project name, so we can
# figure out the development server's name
# TODO: make this code suck less
sub get_catalyst_project_name {
	my $project_dir = shift;
	return unless $project_dir;

    require File::Spec;
    my @dirs = File::Spec->splitdir($project_dir);
    my $project_name = lc($dirs[-1]);
    $project_name =~ tr{-}{_};
    
    return $project_name;
}

sub find_file_from_output {
	my $filename = shift;
	my $output_text = shift;
	
	$filename .= '.pm';
	
	if ($output_text =~ m{created "(.+$filename(?:\.new)?)"}) {
		return $1;
	}
	else {
		return; # sorry, not found
	}
}

sub get_document_base_dir {	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	my $filename = $doc->filename;
	return Padre::Util::get_project_dir($filename);
}

42;
