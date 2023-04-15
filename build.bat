@echo off
set name=hccmd
sjasmplus.exe %name%.asm --lst --lstlab
REM Put binary in TAP file.
HCDisk2.exe format %name%.tap -y : open %name%.tap : bin2bas rem %name%.bin run 32768 : exit
del %name%.bin
REM Put binary in DSK file.
HCDisk2.exe format %name%.dsk -t 2 -y : open %name%.dsk : tapimp hccmd.tap : dir : exit
REM Put source code, readme in DSK file.
for %%f in (*.asm;*.txt;*.bat) do HCDisk2.exe open %name%.dsk : put %%f : exit
HCDisk2.exe open %name%.dsk : put hccmd.scr -t b -s 16384 : dir : exit

