use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Padre::Plugin::LineFilter',
    AUTHOR              => 'Keedi Kim <keedi@perl.kr>',
    VERSION_FROM        => 'lib/Padre/Plugin/LineFilter.pm',
    ABSTRACT_FROM       => 'lib/Padre/Plugin/LineFilter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Padre-Plugin-LineFilter-*' },
);
