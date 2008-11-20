use strict;
use warnings;

use lib 'inc';
use Padre::Install;
use Config;

if (not $Config{usethreads}) {
	warn "Padre requires a perl built using threads\n";
	exit 0;
}

my %prereqs = (
	'perl'                    => '5.008',

	'Carp'                    => 0,
	'Class::Adapter'          => '1.05',
	'Cwd'                     => 0,
	'Data::Dumper'            => 0,
	'File::Spec'              => 0,
	'File::Spec::Functions'   => 0,
	'File::Basename'          => 0,
	'FindBin'                 => 0,
	'Getopt::Long'            => 0,
	'HTML::Parser'            => '3.58',
	'HTML::Entities'          => '3.57',
	'List::Util'              => 0,
	'IO::Socket'              => 0,
	'Term::ReadLine'          => 0,
	'Module::Refresh'         => 0,
	'App::Ack'                => '1.86',
	'Class::Autouse'          => '1.26',
	'Class::Unload'           => 0,
	'DBD::SQLite'             => 0,
	'DBI'                     => 0,
	'File::Copy::Recursive'   => 0,
	'File::Find::Rule'        => 0,
	'File::HomeDir'           => 0,
#	'File::LocalizeNewlines'  => '1.10',
	'File::ShareDir'          => '1.00',
	'File::ShareDir::PAR'     => '0.03',
	'File::Slurp'             => 0,
	'File::Which'             => '0.05',
	'Module::Inspector'       => '0.04',
	'Module::Starter'         => '1.50',
	'ORLite'                  => '0.15',
	'PAR'                     => '0.970',
	'Pod::POM'                => 0,
	'Pod::Simple'             => '3.07',
	'Probe::Perl'             => '0.01',
	'PPI'                     => '1.203',
	'Text::Diff'              => '0.35',
	'Text::FindIndent'        => '0.01',
	'YAML::Tiny'              => '1.32',
	'Wx'                      => '0.86',
	'Wx::Perl::Dialog'        => '0.02',
	'Wx::Perl::ProcessStream' => 0,
);



my $builder = Padre::Install->new(
	module_name           => 'Padre',
	license               => 'perl',
	dist_author           => 'Gabor Szabo',
	create_makefile_pl    => 0,
	create_readme         => 0,
	recursive_test_files  => 0,

	script_files          => [ 'script/padre' ],
	requires              => \%prereqs,
	build_requires        => {
#		'Test::Compile'             => '0.08', # does not work on Windows
		'Test::More'                => '0.47',
		'Test::Exception'           => 0,
		'Test::NoWarnings'          => 0,
		'Test::NeedsDisplay'        => '1.05',
	},
	meta_merge => {
		resources => {
			homepage    => 'http://padre.perlide.org/',
			bugtracker  => 'http://padre.perlide.org/',
			Repository  => 'http://svn.perlide.org/padre',
			MailingList => 'http://mail.perlide.org/mailman/listinfo/padre-dev',
		},
		no_index => {
			directory => [ qw{ t xt eg share inc} ],
		},
	},
);

#use File::Spec::Functions qw(catdir);
#$builder->install_path->{share} = catdir($builder->install_path->{lib}, 'auto', 'share', 'dist', $builder->dist_name);
$builder->config('usethreads');

$builder->create_build_script();



sub check_wx_version {

	require Wx;
	return if $@;  # missing Wx should be dealt by the standard prereq system

	my $version = Wx::wxVERSION_STRING();
	nono("Could not find Wx::wxVERSION_STRING") if not defined $version;

	print "Found $version\n";
	$version =~ s/wxWidgets\s+//;
	nono("Sorry we don't known this wxWidgets version format: '$version'")
		if $version !~ /^\d+\.\d+(\.\d+)?$/;
	my ($major, $minor, $way_too_minor) = split /\./, $version;
	nono("Padre needs at least version 2.7.x of wxWidgets. this is version $version")
		if $major < 2 or $minor < 7;

	return;
}

sub nono {
	my $msg = shift;
	print STDERR "$msg\n";
	exit 0;
}
