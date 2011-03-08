use strict;
use warnings;

use ExtUtils::CBuilder	();
use Alien::wxWidgets 	();

my @modules = (
	glob('C:\tools\wx-scintilla\src\stc\scintilla\src\*.cxx'),
	'C:\tools\wx-scintilla\src\stc\PlatWX.cpp',
	'C:\tools\wx-scintilla\src\stc\ScintillaWX.cpp',
	'C:\tools\wx-scintilla\src\stc\stc.cpp',
);
	
	#'src/stc/ScintillaWX.cpp',
my @include_dirs = (
	'C:\tools\wx-scintilla\src\stc',
	'C:\tools\wx-scintilla\include',
	'C:\tools\wx-scintilla\src\stc\scintilla\include',
	'C:\tools\wx-scintilla\src\stc\scintilla\src',
	'C:\strawberry\perl\site\lib\Alien\wxWidgets\msw_2_8_10_uni_gcc_3_4\include',
	'C:\strawberry\perl\site\lib\Alien\wxWidgets\msw_2_8_10_uni_gcc_3_4\lib',
);

my @objects = ();
my $builder = ExtUtils::CBuilder->new(quiet => 0);
#for my $module (@modules) {
#	print "Compiling $module\n";
#	my $object_file = $builder->compile(
#		source 			=> $module,
#		include_dirs 		=> \@include_dirs,
#		extra_compiler_flags	=> '-DWXBUILDING -D__WX__ -DSCI_LEXER -DLINK_LEXERS',
#	);
#	push @objects, $object_file;
#}

@objects = (glob('C:\tools\wx-scintilla\src\stc\scintilla\src\*.o'), glob('C:\tools\wx-scintilla\src\stc\*.o'));
my $lib_file = $builder->link(
	module_name 		=> 'stc',
	objects 		=> \@objects,
	extra_linker_flags	=> '-DWXBUILDING -D__WX__ -DSCI_LEXER -DLINK_LEXERS -DWXMAKINGDLL_STC ' .
				   '-LC:\strawberry\perl\site\lib\Alien\wxWidgets\msw_2_8_10_uni_gcc_3_4\lib ' .
				   '-lwxbase28u -lwxmsw28u_core ' .
				   '-IC:\tools\wx-scintilla\src\stc\scintilla\include ' .
				   '-IC:\tools\wx-scintilla\src\stc\scintilla\src',
);
print $lib_file . "\n";

print "\n" . ("-" x 20) . "> Finished\n";

