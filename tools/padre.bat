@echo off
@rem This is used as a launcher for padre in the Padre-on-Strawberry package
@rem The file lives in the tools/ directory in the Padre SVN repository
@rem and it is copied to the c:\strawberry\ directory before zipping the files.

PATH=%PATH%;C:\strawberry\c\bin;C:\strawberry\perl\bin;C:\strawberry\perl\site\bin
padre
