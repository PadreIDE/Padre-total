use v5.10;

use strict;
use warnings;

use feature 'say';
use Alien::wxWidgets;
use File::Basename;

my @modules = (
	glob('src\stc\scintilla\src\*.cxx'),
	'src\stc\PlatWX.cpp',
	'src\stc\ScintillaWX.cpp',
	'src\stc\stc.cpp',
);

my @include_dirs = (
	'-Iinclude',
	'-Isrc\stc\scintilla\include',
	'-Isrc\stc\scintilla\src',
	'-Isrc\stc',
	Alien::wxWidgets->include_path
);

=pod
g++ -c -o gcc_mswudll\stcdll_AutoComplete.o  -O2 -mthreads  -DHAVE_W32API_H -D__WXMSW__      -D_UNICODE   
-I..\..\src\stc\..\..\..\lib\gcc_dll\mswu 
-I..\..\src\stc\..\..\..\include 
-Wall 
-I..\..\src\stc\..\..\include 
-I..\..\src\stc\scintilla\include 
-I..\..\src\stc\scintilla\src 
-D__WX__ -DSCI_LEXER -DLINK_LEXERS -DWXUSINGDLL -DWXMAKINGDLL_STC   
-Wno-ctor-dtor-privacy   
-MTgcc_mswudll\stcdll_AutoComplete.o 
-MFgcc_mswudll\stcdll_AutoComplete.o.d 
-MD -MP 
../../src/stc/scintilla/src/AutoComplete.cxx
=cut

my @objects = ();
for my $module (@modules) {
	say "Compiling $module";
	my $filename = basename($module);
	$filename =~ s/(.c|.cpp|.cxx)$/.o/;
	my $object_name = File::Spec->catfile(dirname($module), "stcdll_$filename");
	my @cmd = (
		Alien::wxWidgets->compiler,
		'-c',
		'-o ' . $object_name,
		'-O2 -mthreads -DHAVE_W32API_H -D__WXMSW__ -D_UNICODE',
		'-Wall ',
		'-DWXBUILDING -D__WXMSW__ -D__WX__ -DSCI_LEXER -DLINK_LEXERS',
		'-D__WX__ -DSCI_LEXER -DLINK_LEXERS -DWXUSINGDLL -DWXMAKINGDLL_STC',
		'-Wno-ctor-dtor-privacy',
		'-MT' . $object_name,
		'-MF' . $object_name . '.d',
		'-MD -MP',
		join( ' ', @include_dirs ),
		$module,
	);
	my $cmd = join( ' ', @cmd );

	#say $cmd;
	system($cmd);
	push @objects, $object_name;
}

=pod
g++ -shared -fPIC -o ..\..\src\stc\..\..\..\lib\gcc_dll\wxmsw28u_stc_gcc_custom.dll 
gcc_mswudll\stcdll_PlatWX.o gcc_mswudll\stcdll_ScintillaWX.o 
gcc_mswudll\stcdll_stc.o gcc_mswudll\stcdll_AutoComplete.o 
gcc_mswudll\stcdll_CallTip.o gcc_mswudll\stcdll_CellBuffer.o gcc_mswudll\stcdll_CharClassify.o gcc_mswudll\stcdll_ContractionState.o gcc_mswudll\stcdll_Document.o gcc_mswudll\stcdll_DocumentAccessor.o gcc_mswudll\stcdll_Editor.o gcc_mswudll\stcdll_ExternalLexer.o gcc_mswudll\stcdll_Indicator.o gcc_mswudll\stcdll_KeyMap.o gcc_mswudll\stcdll_KeyWords.o gcc_mswudll\stcdll_LexAPDL.o gcc_mswudll\stcdll_LexAU3.o gcc_mswudll\stcdll_LexAVE.o gcc_mswudll\stcdll_LexAda.o gcc_mswudll\stcdll_LexAsm.o gcc_mswudll\stcdll_LexAsn1.o gcc_mswudll\stcdll_LexBaan.o gcc_mswudll\stcdll_LexBash.o gcc_mswudll\stcdll_LexBasic.o gcc_mswudll\stcdll_LexBullant.o gcc_mswudll\stcdll_LexCLW.o gcc_mswudll\stcdll_LexCPP.o gcc_mswudll\stcdll_LexCSS.o gcc_mswudll\stcdll_LexCaml.o gcc_mswudll\stcdll_LexCsound.o gcc_mswudll\stcdll_LexConf.o gcc_mswudll\stcdll_LexCrontab.o gcc_mswudll\stcdll_LexEScript.o gcc_mswudll\stcdll_LexEiffel.o gcc_mswudll\stcdll_LexErlang.o gcc_mswudll\stcdll_LexFlagship.o gcc_mswudll\stcdll_LexForth.o gcc_mswudll\stcdll_LexFortran.o gcc_mswudll\stcdll_LexGui4Cli.o gcc_mswudll\stcdll_LexHTML.o gcc_mswudll\stcdll_LexHaskell.o gcc_mswudll\stcdll_LexInno.o gcc_mswudll\stcdll_LexKix.o gcc_mswudll\stcdll_LexLisp.o gcc_mswudll\stcdll_LexLout.o gcc_mswudll\stcdll_LexLua.o gcc_mswudll\stcdll_LexMMIXAL.o gcc_mswudll\stcdll_LexMPT.o gcc_mswudll\stcdll_LexMSSQL.o gcc_mswudll\stcdll_LexMatlab.o gcc_mswudll\stcdll_LexMetapost.o gcc_mswudll\stcdll_LexNsis.o gcc_mswudll\stcdll_LexOpal.o gcc_mswudll\stcdll_LexOthers.o gcc_mswudll\stcdll_LexPB.o gcc_mswudll\stcdll_LexPOV.o gcc_mswudll\stcdll_LexPS.o gcc_mswudll\stcdll_LexPascal.o gcc_mswudll\stcdll_LexPerl.o gcc_mswudll\stcdll_LexPython.o gcc_mswudll\stcdll_LexRebol.o gcc_mswudll\stcdll_LexRuby.o gcc_mswudll\stcdll_LexSQL.o gcc_mswudll\stcdll_LexSmalltalk.o gcc_mswudll\stcdll_LexTADS3.o gcc_mswudll\stcdll_LexScriptol.o gcc_mswudll\stcdll_LexSpecman.o gcc_mswudll\stcdll_LexSpice.o gcc_mswudll\stcdll_LexTCL.o gcc_mswudll\stcdll_LexTeX.o gcc_mswudll\stcdll_LexVB.o gcc_mswudll\stcdll_LexVHDL.o gcc_mswudll\stcdll_LexVerilog.o gcc_mswudll\stcdll_LexYAML.o gcc_mswudll\stcdll_LineMarker.o gcc_mswudll\stcdll_PropSet.o gcc_mswudll\stcdll_RESearch.o gcc_mswudll\stcdll_ScintillaBase.o gcc_mswudll\stcdll_Style.o gcc_mswudll\stcdll_StyleContext.o gcc_mswudll\stcdll_UniConversion.o gcc_mswudll\stcdll_ViewStyle.o gcc_mswudll\stcdll_WindowAccessor.o gcc_mswudll\stcdll_XPM.o gcc_mswudll\stcdll_version_rc.o   -mthreads -L..\..\src\stc\..\..\..\lib\gcc_dll -Wl,--out-implib=..\..\src\stc\..\..\..\lib\gcc_dll\libwxmsw28u_stc.a    -lwxtiff -lwxjpeg -lwxpng  -lwxzlib  -lwxregexu -lwxexpat    -lkernel32 -luser32 -lgdi32 -lcomdlg32 -lwinspool -lwinmm -lshell32 -lcomctl32 -lole32 -loleaut32 -luuid -lrpcrt4 -ladvapi32 -lws2_32 -lodbc32 -lwxmsw28u_core  -lwxbase28u
=cut 
my $dll = 'wxmsw28u_stc_gcc_custom.dll';
say "Linking $dll";
my @cmd = (
	Alien::wxWidgets->compiler,
	'-shared -fPIC -o ' . $dll,
	'-mthreads',
	join( ' ', @objects ),
	'-lgdi32',
	Alien::wxWidgets->libraries(qw(core base)),
);
my $cmd = join( ' ', @cmd );
#say $cmd;
system($cmd);
