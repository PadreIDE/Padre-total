use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use Config;

my @libs = ();
push @libs,'-lresolv' unless $Config{d_inetaton} or $^O eq 'MSWin32';

WriteMakefile(
	      NAME	=> 'IO::Socket::Multicast',
	      VERSION_FROM => 'lib/IO/Socket/Multicast.pm', # finds $VERSION
	      PREREQ_PM => {
			    $^O eq 'MSWin32' ? () : ('IO::Interface' => 0.94),
			   },
	      LIBS	=> \@libs,   # e.g., '-lm' 
	      DEFINE	=> '',     # e.g., '-DHAVE_SOMETHING' 
	      INC	=> '',     # e.g., '-I/usr/include/other' 
);
