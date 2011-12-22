This folder contains copies of the scintilla/src, scintilla/lexers and 
scintilla/include folders from the Scintilla source distribution. 
Please note that 'scintilla/lexers' is copied into scintilla/src folder.

Unneeded *.py was removed. Why? We love Python :)
Unneeded *.properties files are also removed.

We also have the experimental LexPerl6.cxx and a modified
scintilla/src/SciLexer.h to include the Perl 6 syntax highlighter (i.e. lexer).
Once it is stable, we will push it to the Scintilla source distribution. 

wxWidgets-specific code to implement Scintilla is located in the parent folder.

The current version of the Scintilla code is 3.0.2.