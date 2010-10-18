use strict;
use warnings;

use Module::Build 0.36;

my $class = Module::Build->subclass( code => <<'EOF');
	eval { require Locale::Msgfmt; Locale::Msgfmt->import(); };
	sub process_mo_files {
		die("requires Locale::Msgfmt") if(! $INC{'Locale/Msgfmt.pm'});
		msgfmt({
			in => "share/locale/",
			out => "blib/share/locale/"});
	}
EOF

my $builder = $class->new(
	module_name       => 'Padre::Plugin::Alarm',
	license           => 'perl',
	share_dir         => 'blib/share',
	dist_author       => 'Fayland Lam <fayland@gmail.com>',
	dist_version_from => 'lib/Padre/Plugin/Alarm.pm',
	build_requires    => {
		'Test::More' => 0,
	},
	requires => {
		'Padre'       => '0.57',
		'Audio::Beep' => 0,
	},
	add_to_cleanup     => ['Padre-Plugin-Alarm-*'],
	create_makefile_pl => 'passthrough',
	meta_merge         => {
		resources => {
			homepage   => 'http://padre.perlide.org/',
			repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Alarm/',
		}
	},
);

$builder->add_build_element('mo');
$builder->create_build_script();
