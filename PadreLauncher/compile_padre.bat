@echo off
rem Creates Padre launcher C code
del padre.exe if exists
del padre-rc.o if exists
windres padre-rc.rc padre-rc.o
gcc -O2 -mwindows padre.c padre-rc.o -o padre.exe
strip padre.exe