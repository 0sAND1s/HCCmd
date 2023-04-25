HCCommander 1.0
File manager for ICE Felix HC computers
george.chirtoaca@gmail.com, 2023

Options:
1 - List drive A:
2 - List drive B:
3 - View selected file - usefull for text files;
  - 0 - exits viewer
  - 2 - sets line wrap on/off
4 - Read selected file properties from file header: type, start address/line, BASIC lenght
5 - Copy selected file from one drive to the other, from A: to B: or from B: to A:.
6 - Rename selected file
7 - Set/reset file attributes for the selected file: Read Only, Hidden attributes
8 - Delete selected file
9 - Disk menu
  - 1 - Format current disk
  - 2 - Copy disk: efficient disk copy, only occupied disk area is copied, from A: to B: or vice versa
  - 3 - Exit disk menu
0 - Exit program to BASIC, without reset. RUN will re-execute program.
Enter - Process selected file:
      - Program files are executed
	  - Byte files are also executed, using the start address for execution, which might not be the case, so it can cause a crash.
      - Text files are listed
	  - SCREEN$ files are displayed.
Cursor - move selection on screen
Space - continuously read file headers for all files on disk.

Known issues:
- For file copy, the destination file is deleted before copying, without confirmation, if it exist already.
- Format and Disk copy commands don't ask for confirmation.
- File copy and disk copy only work with dual drive setup currently (both A: and B:).
- The file viewer will load all file into RAM, so trying to view files bigger than about 30KB will cause a crash.
- By default, HC computers have drive B: configured for 5.25 inch drives, so using 3.5 drives will work, but errors can be encountered
when accesing the second hald of the disk. There is a strap on the IF1 board that can enable 3.5 drives (80 tracks). Using a Kempston
interface was observed to also has the same effect of enabling 80 tracks for drive B:.

How it can be used:
- Use the included HCCMD.tap tape image file with a program that can play tape images on PC/smart phone, like HCDisk, PlayTZX, Tapir.
It should run fine on these computer models: HC-2000 and HC-91, HC-90, HC-85 with IF1.
- Write the included HCCMD.DSK disk image to a floppy disk using HCDisk, found here: https://sites.google.com/site/georgechirtoaca/projects?authuser=0 .
- Use a floppy disk emulator like GoTek with HC and transfer the HCCMD.DSK disk image on a USB stick.
- Use the Fuse emulator version for HC-2000 by Alex Badea with the HCCMD.DSK disk image. The emulator can be found here: https://sites.google.com/site/georgechirtoaca/projects?authuser=0 .
- Use the HC-2000 emulator by Rares Atodiresei, for the Spectaculator emulator, found here: https://sites.google.com/site/georgechirtoaca/projects?authuser=0 .

Planned features:
- File and disk copy to work with single drive setup too, by alternating source/destination disks.
- Extend file viewer to load partial files, to be able to view files that don't fit entierly in RAM.
- New option for disk copy to send/receive data via COM port to PC, to be able to read/write disk images with a modern PC without floppy controller.
- Extend file viewer with a hex viewer, disassembler, BASIC viewer.
- Add support for the CP/M disk format.