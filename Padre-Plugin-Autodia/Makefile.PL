use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Padre::Plugin::Autodia',
    VERSION_FROM      => 'lib/Padre/Plugin/Autodia.pm', # finds $VERSION
    PREREQ_PM         => {
			  Autodia => 2.10
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
       (AUTHOR         => 'Aaron Trevena <teejay@cpan.org>') : ()),
);
