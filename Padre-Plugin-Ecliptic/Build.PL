use strict;
use warnings;
use Module::Build;


my $class = Module::Build->subclass(code => <<'EOF');
	use Locale::Msgfmt;
	sub process_mo_files {
		msgfmt({
			in => "lib/Padre/Plugin/Ecliptic/share/locale/",
			out => "blib/lib/Padre/Plugin/Ecliptic/share/locale/"});
	}
EOF
my $builder = $class->new(
    module_name         => 'Padre::Plugin::Ecliptic',
    license             => 'perl',
    dist_author         => 'Ahmad M. Zawawi',
    dist_version_from   => 'lib/Padre/Plugin/Ecliptic.pm',
    build_requires => {
		'Test::More'              => '0.86',
		'Test::Exception'         => '0.27',
		'Test::NoWarnings'        => '0.084',
		'Locale::Msgfmt'          => '0.08',
	},
    requires => {
		'Padre'                    => '0.33',
		'Class::XSAccessor'		   => '1.02',	
		'ExtUtils::Install'        => '1.52',
		'File::Which'              => '0.05',
	},
    add_to_cleanup      => [ 'Padre-Plugin-Ecliptic-*' ],
    create_makefile_pl  => 'passthrough',
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Ecliptic/',
        }
    },
);

$builder->add_build_element('mo');
$builder->add_build_element('png');
$builder->create_build_script();
