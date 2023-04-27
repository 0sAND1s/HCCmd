@echo off
SETLOCAL EnableExtensions

set name=hccmd

REM If building for HC, uncomment line bellow, to have a smaller binary. If running on Spectaculator emulator for HC-2000, leave it commented out.
set ROM_FNT=_ROM_FNT_

REM set MAX_RAM=1 to build in 2 blocks, Program and Bytes, to have max available RAM for copy operations.
set MAX_RAM=0
if [%MAX_RAM%]==[0] (set RUN_ADDR=30000) else (
set RUN_ADDR=25000
set LOAD_ADDR=32768
)

REM Put files in DSK image
set SAVE_DSK=1

REM assemble main program
sjasmplus.exe %name%.asm --lst --lstlab --raw=%name%.bin -D%ROM_FNT% -DRUN_ADDR=%RUN_ADDR%
if ERRORLEVEL 1 goto :EOF

REM compress main program
zx0.exe -f %name%.bin %name%.zx0

REM assemble packed binary
sjasmplus.exe unpack.asm --raw=%name%.bin -DRUN_ADDR=%RUN_ADDR%

REM Put binary in TAP file.
if [%MAX_RAM%]==[0] (
HCDisk2.exe format %name%.tap -y : open %name%.tap : bin2bas var %name%.bin run : dir : exit
) else (
echo 10 LOAD "hccmd.bin"CODE : RANDOMIZE USR VAL "%LOAD_ADDR%" > hccmd.bas
HCDisk2.exe format %name%.tap -y : open %name%.tap : basimp hccmd.bas run : put %name%.bin -n hccmd.bin -s %LOAD_ADDR% -t b : dir : exit
del hccmd.bas
)

del %name%.bin
del %name%.zx0

if [%SAVE_DSK%]==[0] goto :EOF

REM Put binary in DSK file.
HCDisk2.exe format %name%.dsk -t 2 -y : open %name%.dsk : tapimp hccmd.tap : dir : exit

REM Put source code, readme in DSK file.
for %%f in (*.asm;*.txt;*.bat) do HCDisk2.exe open %name%.dsk : put %%f : exit
HCDisk2.exe open %name%.dsk : put hccmd.scr -t b -s 16384 : dir : exit

