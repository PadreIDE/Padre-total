use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Padre-Plugin-EmacsMode',
    VERSION_FROM      => 'lib/Padre/Plugin/EmacsMode.pm', # finds $VERSION
    PREREQ_PM         => { Padre => 0.25 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
       (AUTHOR         => 'Aaron Trevena <teejay@cpan.org>') : ()),
);
