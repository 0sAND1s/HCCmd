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

	include "disk.asm"

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
CreateFile:
	ld	a, 9
	jr	BDOS
	
;Input: IX=FCB
OpenFile:
	ld	a, 2
	jr	BDOS

;IN: IX=FCB
CloseFile:
	ld	a, 3
	jr	BDOS

;IN: IX=FCB	
ReadFileBlock:
	ld	a, 7
	jr	BDOS

;IN: IX=FCB
WriteFileBlock:
	ld	a, 8
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

;Will copy a file from A: to B: or vice versa.
;HL=source file name
CopyFile:			
	;Prepare source file
	push hl
		ld 		a, (RWTSDrive)
		inc		a					;Convert to BASIC drive number: 1,2
		call	CreateChannel
		call 	OpenFile
		ld		(CopyFileFCBSrc), ix
	pop hl
	inc  	a						;Cancel if A==$FF
	jr   	z, CopyFileEnd
	
	;Create destination file
	ld		a, (ix)
	xor		%11						;Alternate drive, A->B, B-A
	push	af
	push	hl
		call	DeleteFile			;Delete destination file if it exists, like the CP/M guide recommends.
	pop		hl
	pop		af
	call	CreateChannel
	call 	CreateFile
	ld		(CopyFileFCBDst), ix
	inc  	a						;Cancel if A==$FF
	jr   	z, CopyFileEnd	

FileCopyLoop:				
	ld		b, MAX_SECT_RAM
	ld		ix, CopyFileDMAAddr
	ld		hl, CopyFileDMA
	ld		(ix), l
	ld		(ix+1), h
FileCopyReadLoop:	
	push	bc
		ld		ix, (CopyFileDMAAddr)
		call 	BDOSSetDMA
		inc		ixh
		ld		(CopyFileDMAAddr), ix

		ld		ix, (CopyFileFCBSrc)
		call 	ReadFileBlock
		or		a
		ld		(CopyFileResRead), a
	pop		bc	
	jr		nz, FileCopyWrite		
	djnz	FileCopyReadLoop
		
FileCopyWrite:		
	ld		ix, CopyFileDMAAddr
	ld		hl, CopyFileDMA
	ld		(ix), l
	ld		(ix+1), h
	
	;Calculate how many sectors were read.
	ld		a, MAX_SECT_RAM
	sub		b
	ld		b, a
	
FileCopyWriteLoop:				
	push	bc		
		ld		ix, (CopyFileDMAAddr)
		call 	BDOSSetDMA
		inc		ixh
		ld		(CopyFileDMAAddr), ix
		
		ld		ix, (CopyFileFCBDst)
		call	WriteFileBlock
		or		a
		ld		(CopyFileResWrite), a
	pop		bc	
	jr		nz, CopyFileEnd		
	djnz	FileCopyWriteLoop
		
CopyFileEnd:
	;Check if file ended, if not, continue copying.	
	ld		a, (CopyFileResRead)
	or		a
	jr		z, FileCopyLoop
	
	ld		ix, (CopyFileFCBDst)
	call 	CloseFile				;close destination file
	call 	DestroyChannel
	
	;Don't need to close source file, but must free channel
	ld		ix, (CopyFileFCBSrc)
	call 	DestroyChannel
	
	ld		a, (CopyFileResWrite)

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Reads part of a file
;In: HL = name, DE = file offset in bytes
;Out: FileData = read buffer, DE = end of file
ReadFileSection:	
	ld 		a, (RWTSDrive)
	inc		a					;Convert to BASIC drive number: 1,2
	call	CreateChannel
	call 	OpenFile
	ld		(CopyFileFCBSrc), ix
	inc  	a						;Cancel if A==$FF
	ret		z
	
	;Limit max sectors to read to leave space for the index too.
	ld		b, FileDataSize/SECT_SZ
	;Set destination memory pointer.
	ld		ix, CopyFileDMAAddr
	ld		hl, FileData
	ld		(ix), l
	ld		(ix+1), h
ReadFileSectionLoop:	
	push	bc
		ld		ix, (CopyFileDMAAddr)
		call 	BDOSSetDMA
		inc		ixh
		ld		(CopyFileDMAAddr), ix

		ld		ix, (CopyFileFCBSrc)
		call 	ReadFileBlock
		or		a
		ld		(CopyFileResRead), a
	pop		bc	
	jr		nz, ReadFileSectionEnd		
	djnz	ReadFileSectionLoop
			
ReadFileSectionEnd:
	ld		ix, (CopyFileFCBSrc)
	call 	DestroyChannel
	
	ld		de, (CopyFileDMAAddr)
	dec		d
	ret

	ENDIF
