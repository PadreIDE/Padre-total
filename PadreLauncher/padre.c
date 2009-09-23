/**
 * Padre Minimal Win32 Executable Launcher
 * @author Ahmad M. Zawawi <ahmad.zawawi@gmail.com>
 */
#include <windows.h>
 
/**
 * When called by windows, we simply launch Padre from here
 */
int WINAPI WinMain( HINSTANCE hInstance, HINSTANCE hPrevInstance, 
	LPSTR lpCmdLine, int nCmdShow) 
{

	//Find the the executable's path 
	char strExePath[MAX_PATH] = "";
	int length = GetModuleFileName(NULL, strExePath, MAX_PATH);
	if(length) {
		while( length && strExePath[ length ] != '\\' ) {
			length--;
		}
		if( length ) {
			strExePath[ length + 1 ] = '\0';
		}
	}

	char strWPerl[MAX_PATH] = "";
	strncat(strWPerl, strExePath, MAX_PATH);
	strncat(strWPerl, "wperl.exe", MAX_PATH);

	//At this point we should check if padre script exists or not
	if(_access(strWPerl,0)) {
		MessageBox(NULL, "Cannot find wperl.exe in the current directory", NULL, MB_OK);
		return 1;
	}

	
	//add padre script and add the command line
	char strPadre[MAX_PATH] = "";
	strncat(strPadre, strExePath, MAX_PATH);
	strncat(strPadre, "padre", MAX_PATH);

	//At this point we should check if padre script exists or not
	if(_access(strPadre,0)) {
		MessageBox(NULL, "Cannot find Padre's script in the current directory", NULL, MB_OK);
		return 1;
	}

	strncat(strPadre, " ", MAX_PATH);
	strncat(strPadre, lpCmdLine, MAX_PATH);

	// To use ShellExecute
	LoadLibrary("shell32");

	// Open Padre now..
	HINSTANCE instance;
	ShellExecute(
		NULL,
		"open",
		strWPerl,
		strPadre,
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
