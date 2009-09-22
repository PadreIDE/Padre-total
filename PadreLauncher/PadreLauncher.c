/**
 * Padre minimal Win32 Executable Launcher
 * @author Ahmad M. Zawawi <ahmad.zawawi@gmail.com>
 */
#include <windows.h>
 
/**
 * When called by windows, we simply launch Padre from here
 */
int WINAPI WinMain( HINSTANCE hInstance, HINSTANCE hPrevInstance, 
	LPSTR lpCmdLine, int nCmdShow) 
{

	// To use ShellExecute
	LoadLibrary("shell32");

	// Open Padre now..
	HINSTANCE instance;
	ShellExecute(
		NULL,
		"open",
		"wperl.exe",
		"c:\\strawberry\\perl\\bin\\padre",
		NULL,
		SW_SHOWMAXIMIZED
	);

	// The application's return value
	return 0;
}
/**
# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
*/