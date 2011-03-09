use strict;
use warnings;

use Alien::wxWidgets;

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

my @objects = ();
for my $module (@modules) {
	print "Compiling $module\n";
	my $object_file = $module;
	$object_file =~ s/(.c|.cpp|.cxx)$/.o/;
	my @cmd = (
		Alien::wxWidgets->compiler,
		'-c',
		'-o ' . $object_file,
		'-DWXBUILDING -D__WXMSW__ -D__WX__ -DSCI_LEXER -DLINK_LEXERS',
		join( ' ', @include_dirs ),
		Alien::wxWidgets->libraries(qw(core base)),
		$module,
	);
	my $cmd = join( ' ', @cmd );

	#print $cmd . "\n";
	system($cmd);
	push @objects, $object_file;
}

my $dll = 'stc.dll';
my @cmd = (
	Alien::wxWidgets->compiler,
	'-o ' . $dll,
	'-mdll -s',
	join( ' ', @objects ),
	'-L"C:\strawberry\c\lib"',
	'-DWXBUILDING -D__WXMSW__ -DSCI_LEXER -DLINK_LEXERS -DWXMAKINGDLL_STC -lgdi32',
	Alien::wxWidgets->libraries(qw(core base)),
);
my $cmd = join( ' ', @cmd );
print $cmd . "\n";
system($cmd);
