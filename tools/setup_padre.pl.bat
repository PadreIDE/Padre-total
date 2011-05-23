@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
%~dp0perl\bin\perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
%~dp0perl\bin\perl -x -S %0 %*
goto endofperl
@rem ';
#!perl

use 5.008009;
use strict;
use warnings;
use File::Basename qw(dirname);

my $dir = dirname(dirname($^X));
system "$^X $dir/site/bin/padre --desktop";

__END__

:endofperl
