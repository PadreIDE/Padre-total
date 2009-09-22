@echo off
rem Creates Padre launcher C code
del padre.exe
del padre-rc.o
windres padre-rc.rc padre-rc.o
gcc -O2 -mwindows padre.c padre-rc.o -o padre.exe
strip padre.exe