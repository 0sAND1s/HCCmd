@echo off
SETLOCAL EnableExtensions

set name=hccmd
REM Set devel=1 if running on Spectaculator, it will store the fonts in the final binary and won't produce the DSK.
set devel=0
set RUN_ADDR=28000
set VAR_START=EndCode

if [%devel%]==[0] (
set SAVE_DSK=1
REM assemble main program
sjasmplus.exe %name%.asm --lst --lstlab --raw=%name%.bin -D_REAL_HW_ -DRUN_ADDR=%RUN_ADDR% -DVAR_START=%VAR_START% --syntax=f
) else (
set SAVE_DSK=0
REM assemble main program
sjasmplus.exe %name%.asm --lst --lstlab --raw=%name%.bin -DRUN_ADDR=%RUN_ADDR% -DVAR_START=%VAR_START% --syntax=f
)
if ERRORLEVEL 1 goto :EOF


REM compress main program and produce final binary
zx0.exe -f %name%.bin %name%.zx0
sjasmplus.exe unpack.asm --raw=%name%.bin -DRUN_ADDR=%RUN_ADDR%

REM Put binary in TAP file.
HCDisk2.exe format %name%.tap -y : open %name%.tap : bin2bas var %name%.bin run : dir : exit

del %name%.bin
del %name%.zx0

if [%SAVE_DSK%]==[0] goto :EOF

REM Put binary in DSK file.
HCDisk2.exe format %name%.dsk -t 2 -y : open %name%.dsk : tapimp hccmd.tap : dir : exit

REM Put source code, readme in DSK file.
for %%f in (*.asm;*.md;*.txt;*.bat) do HCDisk2.exe open %name%.dsk : put %%f : exit
HCDisk2.exe open %name%.dsk : put CopyMnu.scr -t b -s 16384 : put DiskMnu.scr -t b -s 16384 : put BasLst.scr -t b -s 16384 : put HexView.scr -t b -s 16384 : put TextView.scr -t b -s 16384 : put ViewMnu.scr -t b -s 16384 : put LICENSE : dir : exit
