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
	char strParams[MAX_PATH] = "";
	int length = GetModuleFileName(NULL, strParams, MAX_PATH);
	if(length) {
		while( length && strParams[ length ] != '\\' ) {
			length--;
		}
		if( length ) {
			strParams[ length + 1 ] = '\0';
		}
	}

	//add padre script and add the command line
	strncat(strParams, "padre", MAX_PATH);

	//At this point we should check if padre script exists or not
	if(_access(strParams,0)) {
		MessageBox(NULL, "Cannot find Padre's script in the current directory", NULL, MB_OK);
	}
	
	strncat(strParams, " ", MAX_PATH);
	strncat(strParams, lpCmdLine, MAX_PATH);

	// To use ShellExecute
	LoadLibrary("shell32");

	// Open Padre now..
	HINSTANCE instance;
	ShellExecute(
		NULL,
		"open",
		"wperl.exe",
		strParams,
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
