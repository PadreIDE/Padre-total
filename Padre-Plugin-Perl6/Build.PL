use strict;
use warnings;
use Module::Build;

my %requires = (
	'perl'                     => '5.010',
	'Padre'                    => '0.44',
	'Syntax::Highlight::Perl6' => '0.74',
	'Perl6::Refactor'          => '0',
	'URI'                      => '1.37',
	'File::Which'              => '0.05',
	'Class::XSAccessor'        => '1.02',
	'App::Grok'                => '0.19',
	'Perl6::Doc'               => '0.45',
	'HTTP::Status'             => '5.817',
	'Net::HTTP'                => '5.831',
	'Archive::Zip'             => '1.30',
);

if ( $^O =~ /win32/i ) {
	$requires{'Win32::Process'} = '0.14';
}
my $class = Module::Build->subclass( code => <<'EOF');
	eval { require Locale::Msgfmt; Locale::Msgfmt->import(); };
	sub process_mo_files {
		die("requires Locale::Msgfmt") if(! $INC{'Locale/Msgfmt.pm'});
		msgfmt({
			in => "lib/Padre/Plugin/Perl6/share/locale/",
			out => "blib/lib/Padre/Plugin/Perl6/share/locale/"});
	}
EOF
my $builder = $class->new(
	module_name       => 'Padre::Plugin::Perl6',
	license           => 'perl',
	dist_author       => 'Ahmad M. Zawawi and Gabor Szabo',
	dist_version_from => 'lib/Padre/Plugin/Perl6.pm',
	build_requires    => {
		'Test::More'       => '0.86',
		'Test::Exception'  => '0.27',
		'Locale::Msgfmt'   => '0.14',
	},
	requires           => \%requires,
	add_to_cleanup     => ['Padre-Plugin-Perl6-*'],
	create_makefile_pl => 'passthrough',
	meta_merge         => {
		resources => {
			homepage => 'http://padre.perlide.org/',
			repository =>
				'http://svn.perlide.org/padre/trunk/Padre-Plugin-Perl6/',
		}
	},
);

$builder->add_build_element('mo');
$builder->add_build_element('png');
$builder->add_build_element('p5');
$builder->add_build_element('p6');
$builder->create_build_script();
