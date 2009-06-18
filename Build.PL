use strict;
use warnings;
use Module::Build;



my %requires = (
	'perl'                     => '5.010',
	'Padre'                    => '0.33',
	'Syntax::Highlight::Perl6' => '0.61',
	'URI'                      => '1.37',
	'File::Which'              => '0.05',
	'Class::XSAccessor'        => '1.02',
);

if($^O =~ /win32/i) {
	$requires{'Win32::Process'} = '0.14';
}

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::Perl6',
    license             => 'perl',
    dist_author         => 'Ahmad M. Zawawi and Gabor Szabo',
    dist_version_from   => 'lib/Padre/Plugin/Perl6.pm',
    build_requires => {
		'Test::More'              => '0.86',
		'Test::Exception'         => '0.27',
		'Test::NoWarnings'        => '0.084',
		'Test::NeedsDisplay'      => '1.05',
	},
    requires => \%requires,
    add_to_cleanup      => [ 'Padre-Plugin-Perl6-*' ],
    create_makefile_pl  => 'traditional',
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Perl6/',
        }
    },
);

$builder->add_build_element('mo');
$builder->add_build_element('png');
$builder->add_build_element('p5');
$builder->create_build_script();
