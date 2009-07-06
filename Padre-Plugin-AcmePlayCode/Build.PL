use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass( code => <<'EOF');
        eval { require Locale::Msgfmt; Locale::Msgfmt->import(); };
        sub process_mo_files {
                die("requires Locale::Msgfmt") if(! $INC{'Locale/Msgfmt.pm'});
                msgfmt({
                        in => "share/locale/",
                        out => "blib/lib/Padre/Plugin/AcmePlayCode/share/locale/"});
        }
EOF
my $builder = $class->new(
    module_name         => 'Padre::Plugin::AcmePlayCode',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/AcmePlayCode.pm',
    build_requires => {
        'Test::More' => 0,
        'Locale::Msgfmt'   => '0.08',
    },
    requires => {
        'Acme::PlayCode' => 0,
        'Padre' => '0.26',
    },
    add_to_cleanup      => [ 'Padre-Plugin-AcmePlayCode-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-AcmePlayCode/',
        }
    },
);

$builder->add_build_element('mo');
$builder->create_build_script();
