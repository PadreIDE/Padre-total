This directory should contain only automatically generated files but
for now we need to manually fix them so we keep them in version control.

1)
run a command like this:
svn diff http://svn.perlide.org/padre/tags/Padre-0.29/Makefile.PL http://svn.perlide.org/padre/tags/Padre-0.32/Makefile.PL
and update the list of dependencies in package.xml and Padre.ppd

2) Change the version number of Padre in package.xml, Padre.ppd  and summary.ppm


3) update the link to the Padre-XX.tar.gz file in  package.xml and Padre.ppd
