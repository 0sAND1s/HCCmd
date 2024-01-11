@echo off
SETLOCAL EnableExtensions

set name=hccmd
REM Set devel=1 if running on Spectaculator, it will store the fonts in the final binary and won't produce the DSK.
set devel=0
REM Startup address is configured here. Setting it too low causes issues.
set RUN_ADDR=26000
REM Variables zone can be set after the code or if the code is put in upper RAM, variables are put in lower RAM.
set VAR_START=EndCode

if [%devel%]==[0] (
set SAVE_DSK=1
set REAL_HW=-D_REAL_HW_
set LST=
) else (
set SAVE_DSK=0
set REAL_HW=
set LST=--lst --lstlab
)

REM assemble main program
sjasmplus.exe %name%.asm %LST% --raw=%name%.bin %REAL_HW% -DRUN_ADDR=%RUN_ADDR% -DVAR_START=%VAR_START% -DLANG_EN=1 --syntax=f
if ERRORLEVEL 1 goto :EOF
sjasmplus.exe %name%.asm %LST% --raw=%name%RO.bin %REAL_HW% -DRUN_ADDR=%RUN_ADDR% -DVAR_START=%VAR_START% -DLANG_EN=0 --syntax=f

REM compress main program and produce final binary
zx0.exe -f %name%.bin %name%.zx0
zx0.exe -f %name%RO.bin %name%RO.zx0
sjasmplus.exe unpack.asm --raw=%name%.unpacker -DRUN_ADDR=%RUN_ADDR%
copy /b %name%.unpacker + %name%.zx0 %name%.out
copy /b %name%.unpacker + %name%RO.zx0 %name%RO.out

REM Put binary in TAP file.
HCDisk2.exe format %name%.tap -y : open %name%.tap : bin2bas var %name%.out run : bin2bas var %name%RO.out runRO : dir : exit

del %name%.bin %name%.zx0 %name%RO.bin %name%RO.zx0 %name%.out %name%RO.out %name%.unpacker

if [%SAVE_DSK%]==[0] goto :EOF

REM Put binary in DSK file.
HCDisk2.exe format %name%.dsk -t 2 -y : open %name%.dsk : tapimp %name%.tap : dir : exit

REM Put source code, readme in DSK file.
for %%f in (*.asm;*.md;*.txt;*.bat) do HCDisk2.exe open %name%.dsk : put %%f : exit
for %%f in (*.scr) do HCDisk2.exe open %name%.dsk : put %%f -t b -s 16384 : exit
HCDisk2.exe open %name%.dsk : put LICENSE : dir : exit
