@echo off
rem Creates Padre launcher C code
del padre.exe
gcc -Os -mwindows padre.c -o padre.exe
strip padre.exe