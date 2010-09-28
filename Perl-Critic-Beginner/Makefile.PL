use ExtUtils::MakeMaker;
WriteMakefile (
          'PL_FILES' => {},
          'INSTALLDIRS' => 'site',
          'NAME' => 'Perl::Critic::Beginner',
          'EXE_FILES' => [],
          'VERSION_FROM' => 'lib/Perl/Critic/Beginner.pm',
          'PREREQ_PM' => {
                           'Test::More' => 0,
                           'Perl::Critic' => '1.082',
                           'Readonly' => '1.03'
                         }
        )
;