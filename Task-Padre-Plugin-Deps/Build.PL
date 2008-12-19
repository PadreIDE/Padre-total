use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Task::Padre::Plugin::Deps',
    license             => 'perl',
    dist_author         => 'Gabor Szabo <szabgab@gmail.com>',
    #dist_version_from   => 'lib/Task/Padre/Plugin/Deps.pm',
    dist_version        => '0.01',
    requires => {
        'perl'                    => '5.008',

        'Padre'                   => '0.16',
        'Wx::Perl::Dialog'        => '0.02',

        # we need these to be installed on target machines in
        # order to make it easy to install the Plugins themself
        'Test::More'              => 0,
        'Test::NeedsDisplay'      => '1.05',
        'Module::Build'           => 0,
        'Module::Install'         => 0,

		# Padre::Plugin::AcmePlayCode   0.02,
		'Acme::PlayCode' => 0,
		
		# Padre::Plugin::Alarm
		'Audio::Beep'    => 0,
		
		# Padre::Plugin::CSS 0.02
		'WebService::Validator::CSS::W3C' => 0,
		'CSS::Minifier::XS' => 0,

		# Padre::Plugin::CPAN 0.03
		'CPAN'           => 0,

		# Padre::Plugin::Encrypt  0.01
		'Crypt::CBC' => 0,
        'Crypt::Blowfish' => 0,
        
        # Padre::Plugin::HTML 0.03
        'XML::XPath' => 0,
        'WebService::Validator::HTML::W3C' => 0,
        'HTML::Tidy' => 0,
        'HTML::Lint' => 0,

		# Padre::Plugin::HTMLExport
		'Syntax::Highlight::Engine::Kate' => 0,

        # Padre::Plugin::InstallPARDist',
        'ExtUtils::InferConfig'   => '0.02',
        'ExtUtils::InstallPAR'    => '0.01',
        'LWP::Simple'             => '0',
        
        # Padre::Plugin::JavaScript 0.22
        'JavaScript::Beautifie'   => '0.03',
        'JavaScript::Minifier::XS' => 0,

        # Padre::Plugin::PAR',
        'PAR::Packer'             => 0,

		# Padre::Plugin::PerlCritic 0.03
		'Perl::Critic' => 0,

        # Padre::Plugin::PerlTidy 0.01
        'Perl::Tidy'              => 0,

		# Padre::Plugin::Pip 0.13
        'pip'                     => '0.13',
        
        # Padre::Plugin::XML
        'XML::Tidy' => 0,

    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Task-Padre-Plugin-Deps-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
