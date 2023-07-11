HCCommander 1.0
File manager for ICE Felix HC computers
george.chirtoaca@gmail.com, 2023

Required hardware: HC-2000, HC-91+IF1, HC-90+IF1, HC-85+IF1.

Options:
1 - List drive A:
2 - List drive B:
3 - View selected file - usefull for text files;
  - 0 - exits viewer
  - 2 - sets line wrap on/off
4 - Read selected file properties from file header: type, start address/line, BASIC lenght
5 - Copy - file copy menu shows up
	- 0 - Exit copy menu
	- 1 - Copy selected file from current drive to current drive, asking for disk change confirmation between source and destination disks
	- 2 - Copy selected file from one drive to the other, from A: to B: or from B: to A:
	- 3 - Copy selected file from current drive to the COM port. In HCDisk the command is 'getif1 filename COM1 19200' for example.
	- 4 - Copy from the COM port to the current drive. New file name will be asked for. In HCDisk the command is 'putif1 filename COM1 19200' for example.
The program will check if a file with that name already exists on destination and will ask for overwrite confirmation.
If file is marked as read-only, an error will be shown.
6 - Rename selected file. The program will check if a file with that name already exists and will abort if it does.
7 - Set/reset file attributes for the selected file: Read Only, Hidden attributes
8 - Delete selected file. If file is marked as read only, an error will be displayed. R/O attribute must be cleared before deleting.
9 - Disk menu - efficient disk copy, only occupied disk area is copied
  - 0 - Exit menu
  - 1 - Copy disk using single drive setup, asking for disk change confirmation between source and destination floppy disks
  - 2 - Copy current disk to the other drive, A: to B: or B: to A:
  - 3 - Copy all current disk data to serial port, for HCDisk on PC
  - 4 - Copy from serial port to current disk, from HCDisk on PC.
  - 5 - Format current disk.
0 - Exit with reset.
Enter - Process selected file:
      - Program files are executed
	  - Byte files are also executed, using the start address for execution, which might not be the case, so it can cause a crash.
      - Text files are listed
      - SCREEN$ files are displayed.
Cursor - move selection on screen
Space - continuously read file headers for all files on disk.

Known issues:
- The file viewer sometimes crashes, for large files.
- Using the program on 5.25 disks will report 640KB free instead of 320KB. There's no system call to determine if running on 3.5 or 5.25 floppy drive.
- Format and Disk copy commands don't ask for confirmation.
- By default, HC computers have drive B: configured for 5.25 inch drives, so using 3.5 drives will work, but errors can be encountered
when accesing the second hald of the disk. There is a strap on the IF1 board that can enable 3.5 drives (80 tracks).

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
- Extend file viewer with a hex viewer, disassembler, BASIC viewer.