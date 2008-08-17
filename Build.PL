use strict;
use warnings;

use Module::Build         ();


#check_wx_version();

my $class = Module::Build->subclass(
    class => 'Padre::Install',
    code  => <<'END_SUBCLASS' );

sub ACTION_code {
    my $self = shift;

    $self->SUPER::ACTION_code(@_);

    use FindBin               ();
    use File::Spec::Functions qw(catfile catdir);
    require File::Copy::Recursive;
    import  File::Copy::Recursive qw(dircopy);

    my $dir =  catdir($FindBin::Bin, 'blib', 'lib', 'auto', 'share', 'dist', $self->dist_name);
    dircopy(catfile($FindBin::Bin, 'share'), $dir);
    return;
}


END_SUBCLASS

use File::Spec::Functions qw(catdir);

my $builder = $class->new(
    module_name           => 'Padre',
    license               => 'perl',
    dist_author           => 'Gabor Szabo',
    create_makefile_pl    => 0,
    create_readme         => 0,
    recursive_test_files  => 0,

    script_files          => [ 'script/padre' ],
    requires              => {
        'perl'                    => '5.008',

        'Carp'                    => 0,
        'Cwd'                     => 0,
        'Data::Dumper'            => 0,
        'File::Spec::Functions'   => 0,
        'FindBin'                 => 0,
        'Getopt::Long'            => 0,
        'List::Util'              => 0,
        'IO::Socket'              => 0,
        'Term::ReadLine'          => 0,

        'Class::Accessor'         => 0,
        'DBD::SQLite'             => 0,
        'DBI'                     => 0,
        #'Devel::PerlySense'       => 0, 
        'File::Copy::Recursive'   => 0,
        'File::HomeDir'           => 0,
        'File::LocalizeNewlines'  => '1.10',
        'File::ShareDir'          => '1.00',
        'File::Slurp'             => 0,
	'Module::Inspector'       => '0.04',
        'Pod::POM'                => 0,
        'Pod::Simple'             => 0,
	'Probe::Perl'             => '0.01',
        'YAML::Tiny'              => '1.32',
        'Wx'                      => 0,
        'Wx::Perl::ProcessStream' => 0,


    },
    build_requires        => {
        'Test::More'                => '0.47',
        'Test::Exception'           => 0,
        'Test::NoWarnings'          => 0,
    },
    meta_merge => {
        resources => {
            homepage    => 'http://padre.perlide.org/',
            bugtracker  => 'http://padre.perlide.org/',
            Repository  => 'http://svn.perlide.org/padre',
    #        MailingList => 'http://mail.perlide.org/listinfo/padre',
        },
    },
);

#$builder->install_path->{share} = catdir($builder->install_path->{lib}, 'auto', 'share', 'dist', $builder->dist_name);

$builder->create_build_script();



sub check_wx_version {

    require Wx;
    return if $@;  # missing Wx should be dealt by the standard prereq system

    my $version = Wx::wxVERSION_STRING();
    nono("Could not find Wx::wxVERSION_STRING") if not defined $version;

    print "Found $version\n";
    $version =~ s/wxWidgets\s+//;
    nono("Sorry we don't known this wxWidgets version format: '$version'")
        if $version !~ /^\d+\.\d+(\.\d+)?$/;
    my ($major, $minor, $way_too_minor) = split /\./, $version;
    nono("Padre needs at least version 2.7.x of wxWidgets. this is version $version")
        if $major < 2 or $minor < 7;

    return;
}

sub nono {
    my $msg = shift;
    print STDERR "$msg\n";
    exit 0;
}
