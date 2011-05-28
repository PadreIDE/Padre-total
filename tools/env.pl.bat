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

use Win32::API;
my $SendMessageTimeout = Win32::API->new('user32', 'SendMessageTimeout','NNNPNNP', 'N')
       or die "Get SendMessageTimeout: "  . Win32::FormatMessage (Win32::GetLastError ());

use constant HWND_BROADCAST =>  0xFFFF;
use constant WM_SETTINGCHANGE =>  0x001A;
use constant SMTO_ABORTIFHUNG =>  0x0002;

my $dwResult = pack 'L', 0;
my $lparam = 'Environment';
my $timeout = 5000;
my $result = $SendMessageTimeout-> Call(HWND_BROADCAST, WM_SETTINGCHANGE,
         0, $lparam, SMTO_ABORTIFHUNG, $timeout, $dwResult);

print "SendMessageTimeout result: $result \n";

__END__

:endofperl
