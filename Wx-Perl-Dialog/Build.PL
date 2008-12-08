use strict;
use warnings;
use Module::Build ();

my %prereqs = (
        'perl'                    => '5.008',

        'Exporter'                => 0,
        'File::Copy::Recursive'   => 0,
        'File::Spec'              => 0,
        'File::Spec::Functions'   => 0,
        'FindBin'                 => 0,

        'Wx'                      => 0,
        'Wx::Perl::ProcessStream' => 0,
);



my $class = Module::Build->subclass(
    class => 'Wx::Perl::Dialog::Install',
    code  => <<'END_SUBCLASS' );

sub ACTION_code {
    my $self = shift;

    $self->SUPER::ACTION_code(@_);

    use FindBin               ();
    use File::Spec::Functions qw(catfile catdir);
    require File::Copy::Recursive;
    import  File::Copy::Recursive qw(dircopy);

    my $dir =  catdir($FindBin::Bin, 'blib', 'lib', 'auto', 'share', 'dist', $self->dist_name);
    dircopy(catfile($FindBin::Bin, 'eg'), $dir);
    return;
}

END_SUBCLASS

use File::Spec::Functions qw(catdir);


my $builder = $class->new(
    module_name           => 'Wx::Perl::Dialog',
    license               => 'perl',
    dist_author           => 'Gabor Szabo',
    create_makefile_pl    => 0,
    create_readme         => 0,
    recursive_test_files  => 0,

    script_files          => [ ],
    requires              => \%prereqs,
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
            MailingList => 'http://mail.perlide.org/mailman/listinfo/padre-dev',
        },
        no_index => {
            directory => [ qw{ t eg share } ],
        },
    },
);

$builder->create_build_script();

