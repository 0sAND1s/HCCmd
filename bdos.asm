;BDOS functions - similar to CP/M

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
;Returns A >= 0 if the file exists, returns $FF on error.
;HL=file name, A=drive	
DoesFileExist:
	IFUSED
	;Set temp DMA address to free RAM, to not overwrite file buffer.
	push	af
	push	hl
		ld		ix, FileIdx
		call 	BDOSSetDMA
	pop		hl
	pop		af
	
	call	CreateChannel	
	
	;Uses FindFirst system call.
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
PromptDiskChangeDst:
	ld		hl, MsgInsertDstDsk
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	ld		hl, MsgPressAnyKey
	ld		de, LST_LINE_MSG + 2 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar	
	ret
	
PromptDiskChangeSrc:
	ld		hl, MsgInsertSrcDsk
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	ld		hl, MsgPressAnyKey
	ld		de, LST_LINE_MSG + 2 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar	
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;HL = source file name, A = source drive
;Use cases:
;1. Copy from A: to B: or B: to A:.
;2. Copy from A: to A:, from B: to B: with alternating disks (single drive) - asks for disk swap.
;3. Copy from A:/B: to COM.
;4. Copy from COM to A:/B:.
;Single drive scenario: 
;1. Read first file part, 
;2. Ask for dest disk, 
;3. check if file exists/ask for overwrite, 
;4. create empty dest file, 
;5. write first file part, 
;6. enter copy loop: ask for SRC disk, read file part, ask for DST disk, write file part, check end, loop.
CopyFile:					
	ld 		a, (RWTSDrive)
	inc		a					;Convert to BASIC drive number: 1,2
	ld		(CopyFileSrcDrv), a
	ld		(CopyFileDstDrv), a
	ld		de, CopyFileSrcName
	ld		bc, NAMELEN
	push	hl
	push	bc
	ldir	
	pop		bc
	pop		hl	
	ld		de, CopyFileDstName
	ldir		
	
	;Reset R/O attribute for destination, to allow file write.
	ld		a, (CopyFileDstName+RO_POS)
	res		7, a
	ld		(CopyFileDstName+RO_POS), a
	
	xor		a
	ld		(CopyFileRes), a	
	ld		de, 0
	ld		(FilePosRead), de	
	ld		(FilePosWrite), de	

	ld		a, (CopyFileSrcDrv)
	add		'A'-1
	;Update menu messages with current drive.
	ld		(MsgMenuSingleDrv1), a
	ld		(MsgMenuSingleDrv2), a
	ld		(MsgMenuDualDrv1), a	
	ld		(MsgMenuToComDrv), a
	ld		(MsgMenuFromCOMDrv), a		
	;Update menu messages with the alternate drive.
	ld		a, (CopyFileSrcDrv) 	
	xor		%11	
	add		'A'-1
	ld		(MsgMenuDualDrv2), a
	
	ld		hl, MsgMenuFileCopy
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	ld		hl, MsgMenuBack
	ld		de, LST_LINE_MSG + 2 << 8
	call	PrintStr	
	ld		hl, MsgMenuSingle
	ld		de, LST_LINE_MSG + 3 << 8
	call	PrintStr	
	ld		hl, MsgMenuDual
	ld		de, LST_LINE_MSG + 4 << 8
	call	PrintStr	
	ld		hl, MsgMenuToCOM
	ld		de, LST_LINE_MSG + 5 << 8
	call	PrintStr
	ld		hl, MsgMenuFromCOM
	ld		de, LST_LINE_MSG + 6 << 8
	call	PrintStr			

	call	ReadChar
	ld		(CopySelOption), a
	
	push	af
		ld		b, 6
		call	ClearNMsgLines
	pop		af
		
	;1=single drive copy, 2=dual drive copy, 3=from file to COM, 4=from COM to file				
	cp		'0'
	jr		nz, CopyFileNotExit
	pop		hl	
	jp		ReadKeyLoop
	
CopyFileNotExit:	
	cp		'1'
	jr		z, CopyFileSameDrive
	
	cp		'2'
	jp		z, CopyFileDualDrive
	
	cp		'3'
	jp		z, CopyFileToCOM
	
	cp		'4'
	jp		z, CopyFileFromCOM
	
	pop		hl
	jp		ReadKeyLoop
				
			
;OUT: Z=1 => file doesn't exist or overwrite was confirmed if it does exist.			
CopyFileCheckOverwrite:	
	;Check if destination file exists.
	ld		a, (CopyFileDstDrv)
	ld		hl, CopyFileDstName
	call	DoesFileExist
	inc		a	
	ret		z						;return Z=1 when file doesn't exist
	
	;Ask overwrite confirmation.
	ld		hl, MsgFileOverwrite
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar	
	cp		'y'
	ret								;return Z=1 when user confirmed file overwrite
	

CopyFileCreateNewFile:		
	ld		a, (CopyFileDstDrv)
	ld		hl, CopyFileDstName
	push	af
	push	hl
		call	DeleteFile			;Delete destination file if it exists, like the CP/M guide recommends.
	pop		hl
	pop		af
	call	CreateChannel
	call 	BDOSCreateFile		
	inc  	a						;Cancel if A==$FF
	ret		z
	
	;Close dest file once created.
	push	af
		call	BDOSCloseFile
		call	DestroyChannel	
	pop		af
	ret	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
CopyFileSameDrive:	
	;Read first file section from SRC.
	ld		a, (CopyFileSrcDrv)
	ld		hl, CopyFileSrcName
	call	ReadFileSection	
	ld		a, (CopyFileSectCnt)
	or		a
	ret		z

	;Prompt for DST disk change.
	call	PromptDiskChangeDst
	ld		a, (RWTSDrive)		
	call	BDOSInit
	
	ld		b, 2
	call	ClearNMsgLines
	
	call	CopyFileCheckOverwrite
	ret		nz							
	
	call	CopyFileCreateNewFile
	ret		z		
	
CopyFileSameDriveLoop:				
	ld		a, (CopyFileSectCnt)
	ld		l, a
	ld		h, 0
	ld		de, MsgCopySectors
	call	Byte2Txt
	ld		hl, MsgCopySectors
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr

	ld		a, (CopyFileRes)			;Save read status code.
	push	af
		ld		a, (CopyFileDstDrv)
		ld		hl, CopyFileDstName		
		call	WriteFileSection					
		ld		a, (CopyFileRes)
		ld		l, a
	pop		af
	or		l
	ret		nz							;Exit if read or write had error. Error 1 on read means EOF (some data might still be read).
	
				
	;Prompt for SRC disk change.
	call	PromptDiskChangeSrc
	ld		a, (RWTSDrive)		
	call	BDOSInit
	
	ld		b, 2
	call	ClearNMsgLines

	ld		a, (CopyFileSrcDrv)
	ld		hl, CopyFileSrcName
	call	ReadFileSection	
	ld		a, (CopyFileSectCnt)
	or		a
	ret		z
	
	;Prompt for DST disk change.
	call	PromptDiskChangeDst
	ld		a, (RWTSDrive)		
	call	BDOSInit
	
	ld		b, 2
	call	ClearNMsgLines
	
	jr		CopyFileSameDriveLoop
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
CopyFileDualDrive:	
	ld		a, (CopyFileSrcDrv) 	
	xor		%11	
	ld		(CopyFileDstDrv), a	
	
	call	CopyFileCheckOverwrite
	ret		nz
	
	call	CopyFileCreateNewFile
	ret		z
	
CopyFileDualDriveLoop:			
	ld		a, (CopyFileSrcDrv)
	ld		hl, CopyFileSrcName
	call	ReadFileSection	
	ld		a, (CopyFileSectCnt)
	or		a
	ret		z	
	
	ld		a, (CopyFileSectCnt)
	ld		l, a
	ld		h, 0
	ld		de, MsgCopySectors
	call	Byte2Txt
	ld		hl, MsgCopySectors
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
		
	ld		a, (CopyFileRes)
	push	af
		ld		a, (CopyFileDstDrv)
		ld		hl, CopyFileDstName
		call	WriteFileSection				
		ld		a, (CopyFileRes)	
		ld		l, a
	pop		af
	or		l
	ret		nz
			
	jr		CopyFileDualDriveLoop	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CopyFileToCOM:
	xor		a
	ld		(CopyFileRes), a
	ld		(CopyFileSectCnt), a
	ld		de, 0
	ld		(FilePosRead), de
	
CopyFileToCOMLoop:		
	ld		a, (CopyFileSrcDrv)
	ld		hl, CopyFileSrcName
	call	ReadFileSection	
		
	ld		a, (CopyFileSectCnt)
	or		a
	jr		z, CopyFileToCOMEnd
	
	;Send buffer to COM port.
	ld		hl, FileData
	ld		b, a					;Sector size is 256.
	ld		c, 0
	call	SERTB		
	
	ld		a, (CopyFileRes)
	or		a
	jr		z, CopyFileToCOMLoop
	
CopyFileToCOMEnd:	
	;Reset read error code, as 1 is returned when file is finished reading.
	xor		a
	ld		(CopyFileRes), a	
	
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
CopyFileFromCOM:
	xor		a
	ld		(CopyFileRes), a	
	ld		de, 0
	ld		(FilePosWrite), de
	
	;Must ask for the new file name and check to not exist.	
	ld		hl, MsgNewFileName
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	
	ld		hl, MsgClear
	ld		de, FileData
	ld		bc, NAMELEN
	ldir
	ld		a, $80 | ' '
	ld		(de), a
	ld		de, LST_LINE_MSG + 2 << 8
	ld		hl, FileData
	call	PrintStr
	
	ld		de, LST_LINE_MSG + 2 << 8
	ld		bc, NAMELEN
	call	ReadString
	
	ld		de, FileData
	ld		a, (de)
	cp		' '					;If starting with space, input was canceled.
	ret		z
	
	;Copy new file name
	ld		hl, FileData
	ld		de, CopyFileDstName
	ld		bc, NAMELEN
	ldir
	
	;Check if new name doesn't exist already.
	ld		a, (CopyFileSrcDrv)
	ld		hl, CopyFileDstName
	call	CopyFileCheckOverwrite
	ret		nz	
		
	;Delete and re-create empty destination file		
	ld		a, (CopyFileSrcDrv)
	ld		hl, CopyFileDstName
	call	CopyFileCreateNewFile
	ret		z
	
CopyFileFromCOMLoop:		
	ld		hl, FileData
	ld		bc, FileDataSize
	ld		e, 1				;Exit on timeout, don't get stuck waiting for more data from PC.
	call	SERRB				;BC = Number of bytes read from COM
	ld		a, c
	or		b
	ret		z

	;If C is not 0, add one more sector.
	ld 		a, c
	or		a
	jr		z, CopyFileFromCOMDontInc
	inc		b
CopyFileFromCOMDontInc:	
	ld		a, b				;Sector size is 256			
	ld		(CopyFileSectCnt), a
	ld		a, (CopyFileDstDrv)
	ld		hl, CopyFileDstName	
	call	WriteFileSection	
	
	ld		a, (CopyFileRes)
	or		a
	jr		z, CopyFileFromCOMLoop
	
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
		ld		a, MAX_SECT_BUF
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
	ld		b, a		
	
ReadWriteFileSectionLoop:			
	push	bc
		ld		ix, (CopyFileDMAAddr)		
		call 	BDOSSetDMA		
		inc		ixh
		ld		(CopyFileDMAAddr), ix		
		
		ld		ix, (CopyFileFCB)				
CopyFileOperAddr2 EQU $ + 1
		call 	BDOSReadFileBlockSeq				
		ld		(CopyFileRes), a				
	pop		bc	
	or		a		
	jr		nz, ReadWriteFileSectionEnd		;Exit on read/write error.
	djnz	ReadWriteFileSectionLoop		;Exit on buffer full.
			
ReadWriteFileSectionEnd:
	;Update sector count variable with how many sectors were transfered.
	ld 		a, MAX_SECT_BUF	
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
