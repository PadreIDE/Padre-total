use strict;
use warnings;
use Module::Build;

unless($ENV{PADRE_PLUGIN_PERL6}) {
	warn "\nWARNING: Please set PADRE_PLUGIN_PERL6 to generate translation files.\n\n";
}

my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

sub ACTION_build {
    my $self = shift;

	if($ENV{PADRE_PLUGIN_PERL6}) {
		my $msgfmt = ($^O =~ /win32/i)
			? qq{c:/Program Files/GnuWin32/bin/msgfmt.exe}
			: `which msgfmt`; 
		chomp $msgfmt;
		if ( $msgfmt && -e $msgfmt ) {
			my @pofiles = glob "lib/Padre/Plugin/Perl6/share/locale/*.po";
			foreach my $pof ( @pofiles ) {
				my $mof = $pof;
				$mof =~ s/\.po$/.mo/;
				print qq{Generating $mof\n};
				system qq{"$msgfmt" -o $mof $pof};
			}
		} else {
			die "Could not find $msgfmt!\n";
		}
	}

    $self->SUPER::ACTION_build;	
}

sub ACTION_dist {
		
	if($ENV{PERL6_PLUGIN_DEV}) {
		my $self = shift;
		$self->SUPER::ACTION_dist;
	} else {
		die "You did not enable PERL6_PLUGIN_DEV environment variable.";
	}
}

SUBCLASS


my %requires = (
	'perl'                     => '5.010',
	'Padre'                    => '0.33',
	'Syntax::Highlight::Perl6' => '0.57',
	'URI'                      => '1.37',
	'File::Which'              => '0.05',
	'Class::XSAccessor'        => '1.02',
);

if($^O =~ /win32/i) {
	$requires{'Win32::Process'} = '0.14';
}

my $builder = $class->new(
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
	PL_files => {
		'lib/Padre/Task/p6tokens.pl' => [],  # ignore it please
	},
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
$builder->create_build_script();
