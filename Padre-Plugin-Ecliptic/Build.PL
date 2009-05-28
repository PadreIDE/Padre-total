use strict;
use warnings;
use Module::Build;

unless($ENV{PADRE_PLUGIN_ECLIPTIC}) {
	warn "\nWARNING: Please set PADRE_PLUGIN_ECLIPTIC to generate translation files.\n\n";
}

my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

sub ACTION_build {
    my $self = shift;

	if($ENV{PADRE_PLUGIN_ECLIPTIC}) {
		my $msgfmt = ($^O =~ /win32/i)
			? qq{c:/Program Files/GnuWin32/bin/msgfmt.exe}
			: `which msgfmt`; 
		chomp $msgfmt;
		if ( $msgfmt && -e $msgfmt ) {
			my @pofiles = glob "lib/Padre/Plugin/Ecliptic/share/locale/*.po";
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
		
	if($ENV{PADRE_PLUGIN_ECLIPTIC}) {
		my $self = shift;
		$self->SUPER::ACTION_dist;
	} else {
		die "You did not enable PADRE_PLUGIN_ECLIPTIC environment variable.";
	}
}

SUBCLASS


my %requires = (
);


my $builder = $class->new(
    module_name         => 'Padre::Plugin::Ecliptic',
    license             => 'perl',
    dist_author         => 'Ahmad M. Zawawi',
    dist_version_from   => 'lib/Padre/Plugin/Ecliptic.pm',
    build_requires => {
		'Test::More'              => '0.86',
		'Test::Exception'         => '0.27',
		'Test::NoWarnings'        => '0.084',
		'Test::NeedsDisplay'      => '1.05',
	},
    requires => {
		'Padre'                    => '0.33',
		'Class::XSAccessor'		   => '1.02',	
	},
    add_to_cleanup      => [ 'Padre-Plugin-Ecliptic-*' ],
    create_makefile_pl  => 'traditional',
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
