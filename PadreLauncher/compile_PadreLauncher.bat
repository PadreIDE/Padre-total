@echo off
rem compiles Padre launcher C code
del PadreLauncher.exe
gcc -O2 -Os -mwindows PadreLauncher.c -o PadreLauncher.exe
strip PadreLauncher.exe