#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use autodie qw(:default);

# a temporary script to build an executable on Windows using PAR
my $exe_file = shift or die "Usage: $0 EXE_FILE\n";

my $dir = File::Spec->catdir(dirname(dirname abs_path $0), 'Padre');
chdir $dir;

unlink $exe_file if -e $exe_file;

my @dlls = qw(
	wxbase28u_gcc_custom.dll 
	wxmsw28u_adv_gcc_custom.dll
	wxmsw28u_core_gcc_custom.dll
	mingwm10.dll
);

my $cmd = "pp -o $exe_file script/padre";
foreach my $dll (@dlls) {
	$cmd .= " -l c:/strawberry/perl/vendor/lib/Alien/wxWidgets/msw_2_8_10_uni_gcc_3_4/lib/$dll";
}
print "$cmd\n";
system $cmd;
print "============================= DONE ===============\n";
print "Lunching $exe_file\n";
system $exe_file;


