use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Task::Padre::Plugins',
    license             => 'perl',
    dist_author         => 'Gabor Szabo <szabgab@gmail.com>',
    dist_version_from   => 'lib/Task/Padre/Plugins.pm',
   	requires            => {
		'Padre::Plugin::AcmePlayCode'  => 0,       # depends on Moose
		'Padre::Plugin::Alarm'         => 0,
		'Padre::Plugin::CPAN'          => 0,
		'Padre::Plugin::CSS'           => '0.02',
		'Padre::Plugin::Encrypt'	   => 0,
		'Padre::Plugin::HTML'          => '0.03',
		'Padre::Plugin::HTMLExport'    => 0,
		'Padre::Plugin::JavaScript'    => '0.22',
		'Padre::Plugin::PAR'           => '0.03',
#		'Padre::Plugin::Parrot'       # only for people with Parrot on their computer
#		'Padre::Plugin::PIR'          # this was only a typo
		'Padre::Plugin::PerlCritic'    => 0,
		'Padre::Plugin::PerlTidy'      => 0,
#		'Padre::Plugin::PluginHelper'  => '0.06',  # integrated in Padre
		'Padre::Plugin::Pip'           => '0.13',
#		Padre::Plugin::TabAndSpace                  integrated in Padre
#		Padre::Plugin::UpLowCase                    integrated in Padre
		'Padre::Plugin::ViewInBrowser' => 0,
#		Padre::Plugin::WordStats                    integrated in Padre
		'Padre::Plugin::XML'           => 0,
	},

    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Task-Padre-Plugins-*' ],
    create_makefile_pl => 'traditional',
    meta_merge => {
		resources => {
			homepage    => 'http://padre.perlide.org/',
			bugtracker  => 'http://padre.perlide.org/',
			Repository  => 'http://svn.perlide.org/padre',
			MailingList => 'http://mail.perlide.org/mailman/listinfo/padre-dev',
		},
		no_index => {
			directory => [ qw{ t eg share } ],
		},
	},
);

$builder->create_build_script();
