use strict;
use warnings;
use Module::Build ();


my $builder = Module::Build->new(
	module_name           => 'CPAN::Shell::Wx',
	license               => 'perl',
	dist_author           => 'Gabor Szabo',
	create_makefile_pl    => 'traditional',
	create_readme         => 0,
	recursive_test_files  => 0,

	requires              => {
		'perl'                    => '5.006',
		'CPAN'                    => '0',
	},
	script_files          => [ 'script/wxcpan' ],
	build_requires        => {
		'Test::More'                => '0.47',
	},
	meta_merge => {
		resources => {
			homepage    => 'http://padre.perlide.org/',
			bugtracker  => 'http://padre.perlide.org/',
			Repository  => 'http://svn.perlide.org/padre/trunk/CPAN-Shell-Wx',
			MailingList => 'http://mail.perlide.org/mailman/listinfo/padre-dev',
		},
		no_index => {
			directory => [ qw{ t eg share } ],
		},
	},
);

$builder->create_build_script();

