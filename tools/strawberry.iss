; -- strawberry_perl_with_cream.iss --

; SEE THE DOCUMENTATION FOR DETAILS ON CREATING .ISS SCRIPT FILES!

[Setup]
AppName=Strawberry Perl with Cream
AppVersion=0.03
DefaultDirName=\Strawberry
DefaultGroupName=Strawberry Perl
; UninstallDisplayIcon={app}\MyProg.exe
Compression=lzma2
SolidCompression=yes
SourceDir=c:\strawberry
OutputDir=c:\output
OutputBaseFilename=strawberry-with-cream
;AppComments=
AppContact=http://padre.perlide.org/
; AppCopyright=
AppId=Strawberry_Perl_with_Cream
; AppMutex= TODO!
AppPublisherURL=http://padre.perlide.org/

ChangesAssociations=yes
ChangesEnvironment=yes
;InfoAfterFile=README_FIRST.txt

[Run]
Filename: "{app}\relocation.pl.bat";

[Registry]
; 'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Session Manager/Environment', 
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueName: "Path"; ValueType: expandsz; ValueData: "{olddata};{app}\perl\bin;{app}\perl\site\bin;{app}\c\bin;"
; TODO: remove these during uninstall

[Files]
; Excludes: "cpan_sqlite_log*,cpan/build/*,cpan/sources/*,cpan/Bundle/*"; 
; Source: "*"; DestDir: "{app}"; Flags: "recursesubdirs"

; Use the following to play with the packaging with only a few files
; In production, comment out these lines an enable the one above
Source: "README.txt"; DestDir: "{app}"
Source: "perl\site\bin\padre.exe"; DestDir: "{app}\perl\site\bin\"
Source: "relocation.pl.bat"; DestDir: "{app}"
; C:\Program Files\CollabNet\Subversion Client;%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;C:\strawberry\c\bin;C:\strawberry\perl\site\bin;C:\strawberry\perl\bin;;C:\Str\perl\bin;C:\Str\perl\site\bin;C:\Str\c\bin;

[Icons]
Name: "{group}\Padre"; Filename: "{app}\perl\site\bin\padre.exe"
Name: "{group}\Uninstall"; Filename: "{app}\unins000.exe"
