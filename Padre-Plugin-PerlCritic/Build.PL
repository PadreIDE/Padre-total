use strict;
use warnings;

use Module::Build ();

my $builder = Module::Build->new(
    module_name          => 'Padre::Plugin::PerlCritic',
    license              => 'perl',
    dist_author          => 'Kaare Rasmussen <kaare@cpan.org>',
    create_makefile_pl   => 'traditional',
    create_readme        => 1,
    recursive_test_files => 0,

    requires => {
        'perl'       => '5.008',
        'Perl::Critic' => 0,
        'Padre'      => '0.26',
    },
    build_requires => { 'Test::More' => '0.47', },
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-PerlCritic/',
        }
    },
);

$builder->create_build_script();
