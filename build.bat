@echo off
SETLOCAL EnableExtensions

set name=hccmd
REM Set devel=1 if running on Spectaculator, it will store the fonts in the binary and won't produce the DSK.
set devel=0
REM Set twoblocks=1 if you want maximum buffer size for faster file copy (about 30KB instead of 18KB).
set twoblocks=0
if [%twoblocks%]==[0] (set RUN_ADDR=37000) else (set RUN_ADDR=26000)
set VAR_START=EndCode

if [%devel%]==[0] (
set SAVE_DSK=1
REM assemble main program
sjasmplus.exe %name%.asm --lst --lstlab --raw=%name%.bin -D_REAL_HW_ -DRUN_ADDR=%RUN_ADDR% -DVAR_START=%VAR_START%
) else (
set SAVE_DSK=0
REM assemble main program
sjasmplus.exe %name%.asm --lst --lstlab --raw=%name%.bin -DRUN_ADDR=%RUN_ADDR% -DVAR_START=%VAR_START%
)
if ERRORLEVEL 1 goto :EOF


REM compress main program and produce final binary
zx0.exe -f %name%.bin %name%.zx0
sjasmplus.exe unpack.asm --raw=%name%.bin -DRUN_ADDR=%RUN_ADDR%

REM Put binary in TAP file.
if [%twoblocks%]==[0] (
HCDisk2.exe format %name%.tap -y : open %name%.tap : bin2bas var %name%.bin run : dir : exit
) else (
echo 10 LOAD "%name%"CODE 50000: RANDOMIZE USR 50000 > hccmd.bas
HCDisk2.exe format %name%.tap -y : open %name%.tap : basimp hccmd.bas run : put %name%.bin -n %name% -t b -a %RUN_ADDR% : dir : exit
del hccmd.bas
)

del %name%.bin
del %name%.zx0

if [%SAVE_DSK%]==[0] goto :EOF

REM Put binary in DSK file.
HCDisk2.exe format %name%.dsk -t 2 -y : open %name%.dsk : tapimp hccmd.tap : dir : exit

REM Put source code, readme in DSK file.
for %%f in (*.asm;*.txt;*.bat) do HCDisk2.exe open %name%.dsk : put %%f : exit
HCDisk2.exe open %name%.dsk : put hccmd.scr -t b -s 16384 : put LICENSE : dir : exit