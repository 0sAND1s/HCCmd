HCCommander 1.0

File manager for ICE Felix HC computers

george.chirtoaca@gmail.com, 2023

![ScreenShot](https://raw.githubusercontent.com/0sAND1s/HCCmd/main/Copy.gif)
![ScreenShot](https://raw.githubusercontent.com/0sAND1s/HCCmd/main/Disk.gif)
![ScreenShot](https://raw.githubusercontent.com/0sAND1s/HCCmd/main/BasLst.gif)

Required hardware: HC-2000, HC-91+IF1, HC-90+IF1, HC-85+IF1.

Options:

1 - List drive A:

2 - List drive B:

3 - View selected file - shows BASIC program files as text, or show text files. Max file size is about 25KB.

4 - Read selected file properties from file header: type, start address/line, BASIC lenght

5 - Copy - file copy menu shows up
	
 	- 0 - Exit copy menu
	- 1 - Copy selected file from current drive to current drive, asking for disk change confirmation between source and destination disks
	- 2 - Copy selected file from one drive to the other, from A: to B: or from B: to A:
	- 3 - Copy selected file from current drive to the COM port. In HCDisk the command is 'getif1 filename COM1 19200' for example.
	- 4 - Copy from the COM port to the current drive. New file name will be asked for. In HCDisk the command is 'putif1 filename COM1 19200' for example.
	The program will check if a file with that name already exists on destination and will ask for overwrite confirmation. If file is marked as read-only, an error will be shown.

6 - Rename selected file. The program will check if a file with that name already exists and will abort if it does.

7 - Set/reset file attributes for the selected file: Read Only, Hidden attributes

8 - Delete selected file. If file is marked as read only, an error will be displayed. R/O attribute must be
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
      - Text files are listed
      - SCREEN$ files are displayed.
      
Cursor - move selection on screen

Space - continuously read file headers for all files on disk.

How it can be used:
- Use the included HCCMD.tap tape image file with a program that can play tape images on PC/smart phone, like HCDisk, PlayTZX, Tapir.
- Write the included HCCMD.DSK disk image to a floppy disk using HCDisk.
- Use a floppy disk emulator like GoTek with HC and transfer the HCCMD.DSK disk image on a USB stick.
- Use the Fuse emulator version for HC-2000 by Alex Badea with the HCCMD.DSK disk image.
- Use the HC-2000 emulator by Rares Atodiresei, for the Spectaculator emulator, but rebuild HCCmd with flag develop=1.

How to copy HC BASIC disks over serial cable (COM port):
1. Notice in Windows device manager the name of the COM port (COM1, COM2, etc).
2. Run the latest HCDisk version and open or create a disk image in the format for HC BASIC 3.5.
3. In HCDisk use command 'copyfs to COM1' to copy from HC to PC or command 'copyfs from COM1' to copy from PC to HC.
4. Run the latest HCCmd version and use menu '9-Disk', then option '3. Copy A:->COM' to copy from HC to PC or option '4. Copy COM->A:' to copy from PC to HC.
5. A message will show on PC and on HC showing how many blocks are left to copy. A full disk takes about 7 minutes to copy.

Planned features:
- Extend file viewer with a hex viewer, disassembler.
- Allow selection of multiple files, for operations like delete, copy, attribute change.
