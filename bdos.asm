;BDOS functions - similar to CP/M

;Error codes returned by BDOS/CP/M, taken from https://www.seasip.info/Cpm/bdos.html
;0 OK,
;1 directory full,
;2 disc full,
;9 invalid FCB,
;10(CP/M) media changed;
;0FFh hardware error.	

	IFNDEF	_BDOS_
	DEFINE	_BDOS_

	include "if1.asm"

BDOSInit:
	xor		a
	jr		BDOS


;IN: A = Drive to select
BDOSSelectDisk:
	IFUSED
	ld		ixl, a
	ld		ixh, 0
	ld		a, 1
	jr		BDOS
	ENDIF


BDOSMakeDiskRO:
	IFUSED
	ld		a, 15
	jr		BDOS
	ENDIF
	
;Get Read Only flag
;OUT: HL = bitflags of R/O drives, A = LSb, P = MSb
BDOSGetDiskRO:
	IFUSED
	ld	a, 16
	jr	BDOS
	ENDIF

BDOSGetCurrentDisk:
	IFUSED
	ld		a, 12
	jr		BDOS
	ENDIF


;Create a disk channel for BDOS access (does not open the file)
;IN: HL=name addr, A=drive
;OUT: IX=FCB
CreateChannel:
	ld (FSTR1), hl
	ld h,0
	ld l,a
	ld (DSTR1), hl
	ld l,NAMELEN
	ld (NSTR1), hl
	rst 08
	DEFB 55
	ld bc, CH_FCB			;adjust to get cp/m fcb
	add ix, bc
	ret


;Destroy a BDOS channel
;IN: IX=FCB
DestroyChannel:
	push bc
	ld bc, -CH_FCB			;adjust to get the basic channel
	add ix, bc
	rst 08
	DEFB 56
	pop bc
	ret
	

;Input: IX=FCB
BDOSCreateFile:
	ld	a, 9
	jr	BDOS
	
;Input: IX=FCB
BDOSOpenFile:
	ld	a, 2
	jr	BDOS

;IN: IX=FCB
BDOSCloseFile:
	ld	a, 3
	jr	BDOS


;0 OK,
;1 end of file,
;9 invalid FCB,
;10 (CP/M) media changed; (MP/M) FCB checksum error,
;11 (MP/M) unlocked file verification error,
;0FFh hardware error.

;IN: IX=FCB	
BDOSReadFileBlockSeq:
	ld	a, 7
	jr	BDOS


;0 OK,
;1 directory full,
;2 disc full,
;8 (MP/M) record locked by another process,
;9 invalid FCB,
;10 (CP/M) media changed; (MP/M) FCB checksum error,
;11 (MP/M) unlocked file verification error,
;0FFh hardware error.
	
;IN: IX=FCB
BDOSWriteFileBlockSeq:
	ld	a, 8
	jr	BDOS
	
	
;0 OK
;1 Reading unwritten data
;4 Reading unwritten extent (a 16k portion of file does not exist)
;6 Record number out of range
;9 Invalid FCB	
BDOSReadFileBlockRandom:
	ld	a, 18
	jr	BDOS
	
;0 OK
;2 Disc full
;3 Cannot close extent
;5 Directory full
;6 Record number out of range
;8 Record is locked by another process (MP/M)
;9 Invalid FCB
;10 Media changed (CP/M); FCB checksum error (MP/M)
BDOSWriteFileBlockRandom:
	ld	a, 19
	jr	BDOS	


;Generic BDOS call
;IX=arg, A=function
BDOS:
	ld (HD11), ix
	ld (COPIES), a
	rst 08
	DEFB 57
	ret

;Set DMA address for BDOS
;IX=DMA
BDOSSetDMA:
	ld a, 13
	jr BDOS
	
;In: IX=FCB
BDOSSetRandFilePtr:
	ld	a, 21
	jr	BDOS
	
;In: HL=filename
;Out: HL=file size in bytes from the 128-bytes record count returned by the BDOS function.
GetFileSize:
	IFUSED
	
	ld 		a, (RWTSDrive)
	inc		a					;Convert to BASIC drive number: 1,2	
	call	CreateChannel	
	
	ld		a, 20
	call	BDOS		
	;inc		a
	;jr		z, GetFileSizeEnd				;This function always returns $FF in A, but the result is OK.
		
	ld		l, (ix + FCB_R0)
	ld		h, (ix + FCB_R1)	
	
	;If the file is bigger than $200 * 128 bytes records, we display 0.
	ld		a, 1
	cp		h
	jr		nc, GetFileSizeOK
	ld		hl, 0
	jr		GetFileSizeEnd
	
GetFileSizeOK:	
	;*128 == 2^7
	ld		b, 7
GetFileSizeMul:	
	rl		l
	rl		h
	djnz	GetFileSizeMul

GetFileSizeEnd:
	push	hl
		call	DestroyChannel
	pop		hl

	ret	
	ENDIF
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;HL=file name, A=drive
DeleteFile:
	call	CreateChannel
	
	ld		a, 6
	call	BDOS
	
	call	DestroyChannel
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Returns A > 0 if the file exists
;HL=file name, A=drive	
DoesFileExist:
	IFUSED
	call	CreateChannel	
	
	ld		a, 4
	call	BDOS	
	
	push	af
		call	DestroyChannel
	pop		af
	ret
	ENDIF
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;IN: E0 = RO, E1 = SYS, HL=filename
ChangeFileAttrib:
	ld 		a, (RWTSDrive)
	inc		a					;Convert to BASIC drive number: 1,2
	push	de
	call	CreateChannel
	pop		de
		
	ld		a, (ix + EXT_NAME + RO_POS)
	sla		a								;reset existing attribute flag
	rr		e								;put wanted flag in Carry flag
	rr		a								;put Carry flag in register L
	ld		(ix + EXT_NAME + RO_POS), a		;set wanted flag
	
	ld		a, (ix + EXT_NAME + SYS_POS)
	sla		a
	rr		e
	rr		a
	ld		(ix + EXT_NAME + SYS_POS), a
	
FileAttribSet:
	ld		a, 17
	call	BDOS
	
	call	DestroyChannel
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;HL=original name, DE = new name
;Works only on the same drive.
RenameFile:
	ld 		a, (RWTSDrive)
	inc		a					;Convert to BASIC drive number: 1,2
	push	de
	call	CreateChannel
	pop		de
	
	push	ix					;IX == FCB
	pop		hl	
	ld		bc, 17				;new name must be found at FCB + 16
	add		hl, bc
	ex		de, hl
	ld		a, (RWTSDrive)
	ld		(de), a
	ld		bc, NAMELEN
	ldir
	
	ld		a, 10
	call	BDOS
	
	call	DestroyChannel
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Will copy a file from A: to B: or vice versa.
;HL = source file name, A = source drive
;TODO:
;Use cases:
;1. Copy from A: to B: or B: to A:.
;2. Copy from A: to A:, with alternating disks (single drive) - ask for disk change.
;3. Copy from A:/B: to COM.
;4. Copy from COM to A:/B:.
;Validations:
;1. Ask for destination: to A:/to B:/to COM/from COM. 
;2. Ask for new name (except to COM), default to current name, allow changing.
;3. Check if destination file name exists for A:/B:/from COM. Allow overwrite for different drives, don't allow for same drive.
CopyFile:		
	;Check for 0 size files and ignore them.
	push	hl
		call 	GetFileSize		
		ld		a, h
		or		l
	pop		hl	
	ret		z
		
	ld 		a, (RWTSDrive)
	inc		a					;Convert to BASIC drive number: 1,2
	ld		(CopyFileSrc), a
	ld		de, CopyFileSrc+1
	ld		bc, NAMELEN
	push	hl
	push	bc
	ldir	
	pop		bc
	pop		hl	
	ld		de, CopyFileDst+1
	ldir		
	
	xor		a
	ld		(CopyFileRes), a	
	
	ld		hl, MsgAskCopyDest
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar	
	;make upper case
	and		%11011111
	cp		'A'
	;exit on invalid option
	ret		c
	cp		'C'+1
	ret		nc
	
	ld		(MsgCopyFileDrv), a
	sub		'A'-1
	ld		(CopyFileDst), a	
	
	ld		hl, MsgCopyFile
	ld		de, LST_LINE_MSG + 2 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr		
	
		
	ld		a, (CopyFileSrc)
	ld		b, a
	ld		a, (CopyFileDst)
	cp		b
	jr		z, CopyFileSameDrive
	jr		CopyFileCheckOverwrite
	
	;Skip COM copy for now.
	;cp		3			;'C'
	;ret		z
	
CopyFileSameDrive:
	ld		hl, MsgInsertDstDsk
	ld		de, LST_LINE_MSG + 3 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	ld		hl, MsgPressAnyKey
	ld		de, LST_LINE_MSG + 4 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar	

	ld		a, (RWTSDrive)	
	;call 	BDOSSelectDisk	
	call	BDOSInit

CopyFileCheckOverwrite:	
	;Check if destination file exists.
	ld		a, (CopyFileDst)
	ld		hl, CopyFileDst+1
	call	DoesFileExist
	inc		a	
	jr		z, CopyFileDestNotExist
	
	;Ask overwrite confirmation.
	ld		hl, MsgFileOverwrite
	ld		de, LST_LINE_MSG + 4 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar	
	cp		'y'
	ret		nz	
	
CopyFileDestNotExist:	
	;Delete and re-create empty destination file		
	ld		a, (CopyFileDst)
	ld		hl, CopyFileDst+1
	push	af
	push	hl
		call	DeleteFile			;Delete destination file if it exists, like the CP/M guide recommends.
	pop		hl
	pop		af
	call	CreateChannel
	call 	BDOSCreateFile		
	inc  	a						;Cancel if A==$FF
	jp   	z, CopyFileEnd	
	
	;Close dest file once created.
	call	BDOSCloseFile
	call	DestroyChannel
	
	ld		de, 0
	ld		(FilePosRead), de	
	ld		(FilePosWrite), de	

CopyFileLoop:					
	;If copying on different drives, don't prompt for disk change.
	ld		a, (CopyFileSrc)
	ld		b, a
	ld		a, (CopyFileDst)
	cp		b
	jr		nz, CopyFileNotSameDrive1
	
	ld		hl, MsgInsertSrcDsk
	ld		de, LST_LINE_MSG + 3 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	ld		hl, MsgPressAnyKey
	ld		de, LST_LINE_MSG + 4 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar		
	
	ld		a, (RWTSDrive)		
	;call 	BDOSSelectDisk
	call	BDOSInit
		
CopyFileNotSameDrive1:		
	ld		a, (CopyFileSrc)
	ld		hl, CopyFileSrc+1
	call	ReadFileSection
	ld		a, (CopyFileRes)
	push	af
	
		;If copying on different drives, don't prompt for disk change.
		ld		a, (CopyFileSrc)
		ld		b, a
		ld		a, (CopyFileDst)
		cp		b
		jr		nz, CopyFileNotSameDrive2
	
		ld		hl, MsgInsertDstDsk
		ld		de, LST_LINE_MSG + 3 << 8
		ld		a, SCR_DEF_CLR | CLR_FLASH
		call	PrintStrClr
		ld		hl, MsgPressAnyKey
		ld		de, LST_LINE_MSG + 4 << 8
		ld		a, SCR_DEF_CLR | CLR_FLASH
		call	PrintStrClr
		call	ReadChar	

		ld		a, (RWTSDrive)				
		;call 	BDOSSelectDisk		
		call	BDOSInit

CopyFileNotSameDrive2:	
		ld		a, (CopyFileDst)
		ld		hl, CopyFileDst+1
		call	WriteFileSection				
		ld		a, (CopyFileRes)
		ld		b, a
	pop		af
	or		b
	ret		nz
		
	;Check if file ended, if not, continue copying.		
	
	ld		a, (CopyFileSectCnt)
	dec		a
	ld		(CopyFileSectCnt), a
	or		a
	jr		nz, CopyFileLoop	

CopyFileEnd:	
	ret

;Reads/Writes disk file portion to/from memory. 
;Meant to be used with 2 step copy operation: 1) read part of file to RAM, 2) write from RAM to destination file, at specified position.
;This should work with single-drive file copy from one disk to another.
;In: A = drive, HL = name, FilePosRead/FilePosWrite = file offset in 128 byte records
;Out: FileData = read buffer, DE = end of data address, CopyFileRes = result code, FilePosRead/FilePosWrite are updated
;
;http://www.gaby.de/cpm/manuals/archive/cpm22htm/ch5.htm#Function_34:
;"Note that reading or writing the last record of an extent in random mode does not cause an automatic extent switch as it does in sequential mode."
;Must use sequential read/write. But for the first operation must use random read/write.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ReadFileSection:
	ld		de, BDOSReadFileBlockRandom
	ld		(CopyFileOperAddr1), de
	ld		de, BDOSReadFileBlockSeq
	ld		(CopyFileOperAddr2), de
	ld		de, FilePosRead
	ld		(CopyFilePtr), de
	ld		(CopyFilePtr2), de
	
	;Limit max sectors to read to leave space for the index too.
	push	af
		ld		a, FileDataSize/SECT_SZ
		ld		(CopyFileSectCnt), a
	pop		af
	jr		ReadWriteFileSection

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteFileSection:
	ld		de, BDOSWriteFileBlockRandom
	ld		(CopyFileOperAddr1), de
	ld		de, BDOSWriteFileBlockSeq
	ld		(CopyFileOperAddr2), de
	ld		de, FilePosWrite
	ld		(CopyFilePtr), de
	ld		(CopyFilePtr2), de		
	

;Common routine for both read and write operations. Code is patched to execute either read or write.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
ReadWriteFileSection:				
	call	CreateChannel	
	ld		(CopyFileFCB), ix	
	call 	BDOSOpenFile		
	inc  	a						;Cancel if A==$FF
	ret		z			
	
	;Set DMA initial pointer = FileData
	push	ix
		ld		hl, FileData
		ld		ix, CopyFileDMAAddr	
		ld		(ix), l
		ld		(ix+1), h
		ld		ix, FileData
		call 	BDOSSetDMA
	pop		ix
	
CopyFilePtr EQU $+2
	;Update file pointer using read/write random call.
	ld		de, (FilePosRead)		
	ld		(ix + FCB_R0), e
	ld		(ix + FCB_R1), d		
CopyFileOperAddr1 EQU $ + 1	
	call 	BDOSReadFileBlockRandom
	
	ld		(CopyFileRes), a		
	or		a
	jr		nz, ReadWriteFileSectionEnd
	
	ld		a, (CopyFileSectCnt)
	dec		a
	ld		(CopyFileSectCnt), a
	jr		z, ReadWriteFileSectionEnd
	ld		b, a		
	
ReadWriteFileSectionLoop:			
	push	bc
		ld		ix, (CopyFileDMAAddr)
		inc		ixh
		ld		(CopyFileDMAAddr), ix		
		call 	BDOSSetDMA		
		
		ld		ix, (CopyFileFCB)				
CopyFileOperAddr2 EQU $ + 1
		call 	BDOSReadFileBlockSeq		
		
		ld		(CopyFileRes), a		
		or		a		
	pop		bc	
	jr		nz, ReadWriteFileSectionEnd		;Exit on read/write error.
	djnz	ReadWriteFileSectionLoop		;Exit on buffer full.
			
ReadWriteFileSectionEnd:
	;Update sector count variable with how many sectors were transfered.
	ld 		a, FileDataSize/SECT_SZ
	sub		b							;Substract the number of sectors left to read when EOF was encountered or buffer ended.	
	ld		(CopyFileSectCnt), a		;Store the number of sectors actually read.

	;Update random access file pointer with the last read value, before file ended or before RAM buffer ended.		
	call	BDOSSetRandFilePtr
	ld		e, (ix + FCB_R0)
	ld		d, (ix + FCB_R1)	
CopyFilePtr2 EQU $+2		
	ld		(FilePosRead), de		
	
	call 	BDOSCloseFile				
	call 	DestroyChannel
		
	ld		de, (CopyFileDMAAddr)
	dec		d
	ret

	ENDIF
