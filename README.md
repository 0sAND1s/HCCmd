HCCommander 1.0 - File manager for ICE Felix HC 8-bit computers - george[dot]chirtoaca[at]gmail[dot]com, 2023

The main features of this program are:
- The UI is using custom 64 text columns display and using semi-graphical chars. Program can be built for English or Romanian language.
- Errors don't crash the program and are displayed using error code and decoded error message.
- Supported disk drive types are BASIC format (not for the CP/M format) with 80 tracks/3.5"/640KB and 40 tracks/5.25"/320KB and the type is detected automatically.
- File listing works for up to 128 files (maximum supported by the file system).
- File properties are shown: size on disk, logical size, file type, file attributes, start address of code blocks/start line of program blocks.
- Disk properties are shown: selected drive (A/B), free space, number of files, total space occupied by files.
- File operations are: view file, read properties from file header, copy files, rename file, change file attributes, delete files.
- Files of any size can be viewed as text or as hex, using up/down scrolling. Program files can also be shown as decoded BASIC code.
- File copy operations support: dual drive copy, single drive copy, from disk to serial port, from serial port to disk, from tape to disk, from disk to tape.
- Disk operations supported: disk copy dual drive, disk copy single drive, disk copy to serial port, disk copy from serial port, format A:/B:.
- Multiple file selection is supported for file copy single drive, file copy dual drive, file delete, file attribute change.

Main windows - with file tagging and program file highlight - latest color scheme

![ScreenShot](https://raw.githubusercontent.com/0sAND1s/HCCmd/main/Main.gif)
![ScreenShot](https://raw.githubusercontent.com/0sAND1s/HCCmd/main/MainRO.gif)


File copy menu

![ScreenShot](https://raw.githubusercontent.com/0sAND1s/HCCmd/main/CopyMnu.gif)
![ScreenShot](https://raw.githubusercontent.com/0sAND1s/HCCmd/main/CpMnuRO.gif)

Disk copy menu

![ScreenShot](https://raw.githubusercontent.com/0sAND1s/HCCmd/main/DiskMnu.gif)
![ScreenShot](https://raw.githubusercontent.com/0sAND1s/HCCmd/main/DsMnuRO.gif)

View file menu

![ScreenShot](https://raw.githubusercontent.com/0sAND1s/HCCmd/main/ViewMnu.gif)

BASIC program listing

![ScreenShot](https://raw.githubusercontent.com/0sAND1s/HCCmd/main/BasLst.gif)

Hex file listing

![ScreenShot](https://raw.githubusercontent.com/0sAND1s/HCCmd/main/HexView.gif)

Text file listing

![ScreenShot](https://raw.githubusercontent.com/0sAND1s/HCCmd/main/TxtView.gif)


Required hardware: HC-2000, HC-91+IF1, HC-90+IF1

Options:

1 - List drive A:

2 - List drive B:

3 - View selected file - any file size is accepted, as file is loaded in parts. About 25KB fit into memory at once.
        - 1 - Shows file as text
	- 2 - Shows file as hex
	- 3 - Auto - depending on file type, it shows file as text or hex or decoded BASIC program.
		
4 - Read file properties from file header: type, start address/line, BASIC lenght; automatically advances to the next file. 
	If the file is of type program, it is highlighted in red.

5 - Copy - file copy menu shows up
	
 	- 0 - Exit copy menu
	- 1 - Copy selected file or all marked files from current drive to current drive, asking for disk change confirmation between source and destination disks
	- 2 - Copy selected file or all marked files from one drive to the other, from A: to B: or from B: to A:
	- 3 - Copy selected file from current drive to the COM port. In HCDisk the command is 'getif1 filename COM1 19200' for example.
	- 4 - Copy from the COM port to the current drive. New file name will be asked for. In HCDisk the command is 'putif1 filename COM1 19200' for example.
	- 5 - Copy block from tape to disk file.
	- 6 - Copy file from disk to tape block.
	
	The program will check if a file with that name already exists on destination and will ask for overwrite confirmation. If file to be overwritten is marked as read-only, an error will be shown.
	Maximum file size accepted for tape to disk/disk to tape copy is 40 KB, which should cover most games. The implementation uses extra 16KB RAM of HC to persist program code to not be overwritten by the large file loaded in RAM for copying.

6 - Rename selected file. The program will check if a file with that name already exists and will abort if it does.

7 - Set/reset file attributes for the selected file or for all marked files: Read Only, Hidden attributes

8 - Delete selected file or all marked files. If file has the read only attribute set, an error will be displayed. R/O attribute must be
cleared before deleting.

9 - Disk menu - efficient disk copy, only occupied disk area is copied

	  - 0 - Exit menu
	  - 1 - Copy disk using single drive setup, asking for disk change confirmation between source and destination floppy disks
	  - 2 - Copy current disk to the other drive, A: to B: or B: to A:
	  - 3 - Copy all current disk data to serial port, for HCDisk on PC
	  - 4 - Copy from serial port to current disk, from HCDisk on PC.
	  - 5 - Format drive A:.
	  - 6 - Format drive B:.
   
0 - Exit to BASIC. Can go back to HCCmd with RUN or CONTINUE keys.

Enter - Process selected file:
      - Program files are executed
      - Byte files are also executed, using the start address for execution, which might not be the case, so it can cause a crash.
      - Untyped/Text files are listed as text
      - SCREEN$ files are displayed.
      
Cursor - move selection on screen

Space - mark file for copy/delete/change attributes; the marked files are highlighted in yellow.


How to transfer the binary:
- Use the included HCCMD.tap tape image file with a program that can play tape images on PC/smart phone, like HCDisk, PlayTZX, Tapir.
- Write the included HCCMD.DSK disk image to a floppy disk using HCDisk using a PC with a floppy disk drive.
- Use a floppy disk emulator like GoTek with HC and transfer the HCCMD.DSK disk image on a USB stick.
- Use the Fuse emulator version for HC-2000 by Alex Badea with the HCCMD.DSK disk image.
- Use the HC-2000 emulator by Rares Atodiresei, for the Spectaculator emulator, but rebuild HCCmd with flag develop=1.

How to copy HC BASIC disks over serial cable (COM port):
1. Notice in Windows device manager the name of the COM port (COM1, COM2, etc).
2. Run the latest HCDisk version and open or create a disk image in the format for HC BASIC 3.5.
3. In HCDisk use command 'copyfs from COM1' to copy from HC to PC or command 'copyfs to COM1' to copy from PC to HC.
4. Run the latest HCCmd version and use menu '9-Disk', then option '3. Copy A:->COM' to copy from HC to PC or option '4. Copy COM->A:' to copy from PC to HC.
5. A message will show on PC and on HC showing how many blocks are left to copy. A full disk takes about 7 minutes to copy.

Thanks to the users who contributed with testing and/or feature requests: Ioan ALEODOR, Vlad Shoby, Adrian-Iulian Mitrofan-Bitca and others.
