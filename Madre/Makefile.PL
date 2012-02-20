use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Madre',
    AUTHOR       => q{YOUR NAME <youremail@example.com>},
    VERSION_FROM => 'lib/Madre.pm',
    ABSTRACT     => 'Sync Server for Padre',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES  => {},
    PREREQ_PM => {
        'File::Remove'               => '1.40', # Test
        'Test::More'                 => '0.47', # Test
        'Try::Tiny'                  => '0.08',
        'YAML'                       => 0,
        'Dancer'                     => '1.3070',
        'ORLite'                     => '1.52',
        'ORLite::Migrate'            => '1.10',
        'DateTime'                   => 0,
        'DateTime::Format::Strptime' => 0,
        'Dancer::Session::Storable'  => 0,
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean => {
        FILES => 'Madre-* data sessions',
    },
);
