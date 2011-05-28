; -- strawberry_perl_with_cream.iss --

; SEE THE DOCUMENTATION FOR DETAILS ON CREATING .ISS SCRIPT FILES!

[Setup]
AppName=Strawberry Perl with Cream
AppVersion=0.03
DefaultDirName={pf}\Strawberry
DefaultGroupName=Strawberry Perl
; UninstallDisplayIcon={app}\MyProg.exe
Compression=lzma2
SolidCompression=yes
OutputDir=c:\output
SourceDir=c:\strawberry
OutputBaseFilename=strawberry-with-cream

[Files]
; Excludes: "cpan_sqlite_log*,cpan/build/*,cpan/sources/*,cpan/Bundle/*"; 
Source: "*"; DestDir: "{app}"; Flags: "recursesubdirs"
;Source: "README.txt"; DestDir: "{app}"
;Source: "perl\site\bin\padre.exe"; DestDir: "{app}"


[Icons]
Name: "{group}\Padre"; Filename: "{app}\perl\site\bin\padre.exe"
