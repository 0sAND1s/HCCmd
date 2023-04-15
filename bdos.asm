;BDOS functions - similar to CP/M

;Error codes returned by BDOS/CP/M, taken from https://www.seasip.info/Cpm/bdos.html
;0 OK,
;1 directory full,
;2 disc full,
;9 invalid FCB,
;10(CP/M) media changed;
;0FFh hardware error.


	ifndef	_BDOS_
	define	_BDOS_

	include "disk.asm"

BDOSInit:
	xor		a
	jr		BDOS


;IN: A = Drive to select
	ifused BDOSSelectDisk
BDOSSelectDisk:
	ld		ixl, a
	ld		ixh, 0
	ld		a, 1
	jr		BDOS
	endif

	ifused BDOSMakeDiskRO
BDOSMakeDiskRO:
	ld		a, 15
	jr		BDOS
	endif
	
;Get Read Only flag
;OUT: HL = bitflags of R/O drives, A = LSb, P = MSb
	ifused BDOSGetDiskRO
BDOSGetDiskRO:
	ld	a, 16
	jr	BDOS
	endif

	ifused BDOSGetCurrentDisk
BDOSGetCurrentDisk:
	ld		a, 12
	jr		BDOS
	endif


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

;FindFirst
;IX=fcb
	ifused BDOSFindFirst
BDOSFindFirst:
	ld a, 4
	jr BDOS
	endif

;FindNext
;IX=fcb
	ifused BDOSFindNext
BDOSFindNext:
	ld a, 5
	jr BDOS
	endif
	

;Set DMA address for BDOS
;IX=DMA
SetDMA:
	ld a, 13
	jr BDOS
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;HL=file name, A=drive
DeleteFile:
	call	CreateChannel
	
	ld		a, 6
	call	BDOS
	
	call	DestroyChannel
	ret
	
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
CopyFileDMA		EQU	DataBuf + 4+1
CopyFileRes		EQU DataBuf + 4
CopyFileFCBDst	EQU	DataBuf + 2
CopyFileFCBSrc	EQU	DataBuf

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
	inc  	a					;Cancel if A==$FF
	jr   	z, CopyFileEnd
	
	;Create destination file
	ld		a, (ix)
	xor		%11					;Alternate drive, A->B, B-A
	call	CreateChannel
	call 	CreateFile
	ld		(CopyFileFCBDst), ix
	inc  	a					;Cancel if A==$FF
	jr   	z, CopyFileEnd
	
	;Set DMA
	ld		ix, CopyFileDMA
	call 	SetDMA
			
FileCopyLoop:	
	ld		ix, (CopyFileFCBSrc)
	call 	ReadFileBlock
	or		a
	jr		nz, CopyFileEnd		
		
	ld		ix, (CopyFileFCBDst)
	call	WriteFileBlock
	or		a
	ld		(CopyFileRes), a
	jr		nz, CopyFileEnd
	
	jr		FileCopyLoop
		
CopyFileEnd:
	ld		ix, (CopyFileFCBDst)
	call 	CloseFile			;close destination file
	call 	DestroyChannel
	
	;Don't need to close source file, but must free channel
	;ld		ix, (CopyFileFCBSrc)
	;call 	CloseFile			
	ld		ix, (CopyFileFCBSrc)
	call 	DestroyChannel
	
	ld		a, (CopyFileRes)

	ret

	endif
