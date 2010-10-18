use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass( code => <<'EOF');
	eval { require Locale::Msgfmt; Locale::Msgfmt->import(); };
	sub process_mo_files {
		die("requires Locale::Msgfmt") if(! $INC{'Locale/Msgfmt.pm'});
		msgfmt({
			in => "lib/Padre/Plugin/Encrypt/share/locale/",
			out => "blib/lib/Padre/Plugin/Encrypt/share/locale/"});
	}
EOF
my $builder = $class->new(
	module_name       => 'Padre::Plugin::Encrypt',
	license           => 'perl',
	dist_author       => 'Fayland Lam <fayland@gmail.com>',
	dist_version_from => 'lib/Padre/Plugin/Encrypt.pm',
	build_requires    => {
		'Test::More'      => 0,
		'Padre'           => '0.57',
		'Crypt::CBC'      => 0,
		'Crypt::Blowfish' => 0,
		'Locale::Msgfmt'  => '0.14',
	},
	add_to_cleanup     => ['Padre-Plugin-Encrypt-*'],
	create_makefile_pl => 'passthrough',
	meta_merge         => {
		resources => {
			homepage   => 'http://padre.perlide.org/',
			repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Encrypt/',
		}
	},
);

$builder->add_build_element('mo');
$builder->create_build_script();
