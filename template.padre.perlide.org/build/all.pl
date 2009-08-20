#!perl
use strict;
use warnings;
use Template;
use File::Spec;
use File::Copy qw(copy);
use File::Find::Rule;
use File::Basename qw(dirname basename);
use YAML::Tiny qw(LoadFile);
use Data::Dumper qw(Dumper);
use Text::Unaccent::PurePerl qw(unac_string);
use Pod::Usage::CommandLine qw(GetOptions pod2usage);
use Time::Piece qw(localtime);
use LWP::Simple qw(get);
use HTML::TreeBuilder::XPath qw();

my %opt;
GetOptions(\%opt, 's|source-directory=s', 'o|output-directory=s') or pod2usage(2);
pod2usage(2) unless $opt{o} and $opt{s};
die "directory $opt{o} does not exist\n" unless -d $opt{o};

# copy static files
for my $file (File::Find::Rule->relative->file()->in("$opt{s}/documentroot")) {
	next if $file =~ m{.svn};
	my $dir = "$opt{o}/" . dirname($file);
	mkdir ($dir);
	my $to = "$dir/" . basename($file);
	copy("$opt{s}/documentroot/$file", $to);
	chmod 0644, $to;
}

my $config = {
		INCLUDE_PATH => "$opt{s}/tt",  # or list ref
		POST_CHOMP   => 1,               # cleanup whitespace
		EVAL_PERL    => 0,               # evaluate Perl code blocks
		OUTPUT_PATH   => $opt{o},
        FILTERS => {
            'id_attr' => sub {
                my ($text) = @_;
                my( $rewrite )=  unac_string $text; # list context pls!
                $rewrite =~ s/\s+/_/g;
		$rewrite;
              }
          },
};

my $tt = Template->new($config);
my ($stash) = LoadFile("$opt{s}/data/stash.yml"); # older version of YAML::Tiny return list ??

{    # scrape the wiki page to keep screenshots in sync
    my $screenshots_xml;
    unless ($screenshots_xml
        = get 'http://padre.perlide.org/trac/wiki/Screenshots') {
        die "could not get the screenshots wiki page\n";
    }
    my $tree = HTML::TreeBuilder::XPath->new_from_content($screenshots_xml);
    my @result_nodes;
    my %seen_version;
    for my $node (
        $tree->findnodes('/html/body/div[3]/div[2]/div/*')->get_nodelist) {
        next if 'h1' eq $node->tag;    # skip page header
        if ('h2' eq $node->tag) {
            my ($version) = [$node->content_list]->[0] =~ /(\d+\.\d+)/;
            if ($version && !exists $seen_version{$version}) {
                $node->attr('id', "v$version");    # must start with letter
                $seen_version{$version} = undef;
            } else {
                $node->attr('id', undef);
            }
            push @result_nodes, $node;
            next;
        }
        if ('p' eq $node->tag) {
            if (ref [$node->content_list]->[0]) {    # has children
                my ($img) = [$node->content_list]->[0]->content_list; # /p/a/img
                $img->attr('title', undef);
                $img->attr('alt',   '');
                push @result_nodes, $img;
            } else {    # has only text
                push @result_nodes, $node;    # /p
            }
        }
    }
    $stash->{screenshots_xml} .= $_->as_XML for @result_nodes;
}
$stash->{build_date} = localtime->ymd;
$stash->{developers}  = read_people($stash->{developers},  'developers');
$stash->{translators} = read_people($stash->{translators}, 'translators');
#print Dumper $stash->{developers};
#print Dumper $stash->{translators};

# for now - only a flat directory processed w/ template.
my $pages_dir = "$opt{s}/tt/pages";
my $page_handle;
opendir( $page_handle, $pages_dir)
	|| die "Failed to opendir '$pages_dir' , $!";
while ( my $file = readdir( $page_handle ) ) {
	next unless $file =~ /\.(html)$/;

	my $template = File::Spec->catfile( 'pages', $file );
	# OUTPUT_PATH is appended to $file by TT
	$tt->process($template , $stash, $file,
		{ binmode => ':utf8' },
	 )
		|| die $tt->error();
}


# TODO: add some error checking and data validation (correct sections? correct fields ?)
sub read_people {
	my $list = shift;
    my $dir  = shift;

	my @developers;
	foreach my $f (@$list) {
		my $file = "$opt{s}/data/$dir/$f.ini";
		open my $fh, '<:utf8', $file or die "Could not open ($file) $!";
		my $section;
		my %data;
		$data{nickname} = $f;
		while (my $line = <$fh>) {
			if ($line =~ /^\[([^\]]+)\]/) {
				$section = $1;
				next;
			}
			next if not $section;
			if ($section eq 'data') {
				if ($line =~ /\S/) {
					chomp $line;
					my ($k, $v) = split /=/, $line, 2;
					$data{$k} = $v;
				}
			} else {
				$data{$section} .= $line;
			}
		}
		push @developers, \%data;
	}
	return \@developers;
}

__END__

=head1 NAME

all.pl - Build the web site at padre.perlide.org

=head1 SYNOPSIS

    all.pl \
      -s ~/svn/padre/template.padre.perlide.org \
      -o ~/public_html/padre.perlide.org

Options:

    --source-directory      base directory where templates etc. are located
    --output-directory      base directory where built web site files go
    --help                  brief help message
    --man                   full documentation

Options can be shortened according to L<Getopt::Long/Case and abbreviations>.

=head1 OPTIONS

=over

=item --source-directory

Mandatory. Specifies the name of the base directory where the web site
templates, static files and source data are located.

This is the checked out local working copy coming from the SVN path
L<http://svn.perlide.org/padre/trunk/template.padre.perlide.org>.

=item --output-directory

Mandatory. Specifies the name of the directory where the web site files
are output after the build.

This directory already needs to exists.

=item --help

Print a brief help message and exits.

=item --man

Prints the manual page and exits.

=back

=head1 DESCRIPTION

C<all.pl> builds the files for the web site at L<http://padre.perlide.org>.
For the screenshots page, HTTP access to
L<http://padre.perlide.org/trac/wiki/Screenshots> is necessary.
