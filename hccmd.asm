

;Define bellow is commented out to include the font binary in RAM, to make it work with Spectaculator HC-2000 emulator, which doesn't seem to implement the paging. 
;If not commented out, it will use the font table in the CPM ROM and the binary will be smaller.
	;DEFINE  _REAL_HW_

;When inserting IF1 variables, our program moves, corrupting our code. 
;So we have to put our code after the program as loaded in RAM.	
	ORG RUN_ADDR
	
Start:	
	IFDEF _REAL_HW_		;If using the fonts from the CP/M ROM, must copy font table to buffer.
		call InitFonts
	ENDIF
	call IF1Init

	;install error handler
	ld	hl, (ERRSP)
	push	hl
	ld	hl, ErrorHandler
	push	hl
	ld	(ERRSP), sp

HCRunInitDisk:	
	;Set track buffer to del marker
	ld	hl, TrackBuf
	ld	d, h
	ld	e, l
	inc	de
	ld	bc, SPT*SECT_SZ
	ld	(hl), DEL_MARKER
	ldir
	
	;Invalidate file cache
	ld	hl, FileCache
	ld	d, h
	ld	e, l
	inc	de
	ld	bc, LST_MAX_FILES*CACHE_SZ - 1
	ld	(hl), 0
	ldir

	;main program
	call	BDOSGetCurrentDrive
	cp	$FF
	jr	nz, DetectTrackCount		
		
	ld		a, DRIVE_A_CPM		;When loaded from tape/serial, no disk is selected, just select drive 1.	

DetectTrackCount:
	push	af
		call	BDOSInit		;This is needed to remove write protection after changing drives.
	pop	af
	ld	(RWTSDrive), a		;If a disk is selected previously, show that disk, it can be disk 2, not always 1.	
	call	BDOSSelectDisk		;Re-select drive 1 or 2.
	
	;Determine if disk is 40 or 80 tracks, to know how many blocks are free.
	ld	e, TRACK_CNT/2
	ld	hl, FileData
	call	ReadOneDiskSector	
	ld	a, (RWTSRes)
	or	a
	ld	hl, MAX_FREE_AU_CNT
	jr	z, DriveIs80Tracks
	ld	hl, MAX_FREE_AU_CNT/2	
DriveIs80Tracks:
	ld	(AUCntMaxFree), hl	

	call 	ReadCatalogTrack
	or		a				;Signal disk read error. On empty drive code 5 is shown.
	jr	z, HCRunCacheFiles
	
	ld	l, a
	ld	h, 0
	ld	de, MsgErrCode
	call	Byte2Txt
	ld	hl, MsgErr
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	BDOSInit
	jp	HCRunInitDisk
	

HCRunCacheFiles:
	call 	GetFileNames	
	
HCRunMain:
	call 	InitUI		
	call	DisplayFilenames
	call	DisplayDiskInfo		
	jp	ReadKeyLoop

HCRunEnd:
	;restore error handler
	pop	hl
	pop	hl
	ld	(ERRSP), hl

	;ret
	jp		$12A2		;Jump to ROM main loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ErrorHandler:
	pop	hl
	ld	(ERRSP), hl

	ld		a, (ERRNR)	;Display the error message
	ld	l, a
	ld	h, 0
	ld	de, MsgErrCode
	call	Byte2Txt
	ld	hl, MsgErr
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr

	ld	a, (ERRNR)
	call	GetErrMsg

	ld	hl, DataBuf
	ld	de, LST_LINE_MSG + 2 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr

	call	ReadChar
	call	BDOSInit
	jp	Start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitUI:
	xor	a
	ld	(SelFile), A	
	ld	a, LST_FIRST_COL + 1
	ld	(NameCol), A
	ld	de, (LST_FIRST_LINE << 8) | LST_FIRST_COL + 1
	ld	(LineCol), de	
	
	call	ClrScr

	ld	hl, SCR_BYTES_PER_LINE * LST_FIRST_LINE + LST_FIRST_COL/2
	ld	bc, (CurrScrAttrAddr)
	add	hl, bc
	ld	(CursorAddr), hl
	
	call	DrawVLines
	
	call	DrawHLines	
	
	ld	hl, VerMsg1
	ld	de, LST_PROG_INFO + 1 << 8
	ld	a, (VerMsg1 + 15)
	or	$80
	ld	(VerMsg1 + 15), a
	call	PrintStr
	ld	hl, VerMsg2
	ld	de, LST_PROG_INFO + 2 << 8
	call	PrintStr		

	ld	a, SCR_LBL_CLR
	ld	de, 23 << 8
	ld	hl, BtnBar
	call	PrintStrClr	
	
	ld	a, SCR_LBL_CLR
	ld	hl, MsgSysInf
	ld	de, LST_PROG_INFO << 8
	call	PrintStrClr

	ld	a, SCR_LBL_CLR
	ld	hl, MsgDskInf
	ld	de, LST_DISK_INFO << 8
	call	PrintStrClr

	ld	a, SCR_LBL_CLR
	ld	hl, MsgFileInf
	ld	de, LST_FILE_INFO << 8
	call	PrintStrClr

	ld	a, SCR_LBL_CLR
	ld	hl, MsgMessages
	ld	de, LST_LINE_MSG << 8
	call	PrintStrClr	

	ld	a, SCR_SEL_CLR
	call	DrawCursor

	call	SetFastKeys

	ret


DisplayDiskInfo:		
	ld	hl, (AUCntMaxFree)
	ld	de, (AUCntUsed)		
	or	a
	sbc	hl, de
	rl	l							;*2, 2K/AU
	rl	h
	
	ld	de, MsgDriveLet
	call	Word2Txt	
	ld	a, (MsgDriveLet+4)
	or	$80
	ld	(MsgDriveLet+4), a
	
	ld	a, (RWTSDrive)
	add	'A'
	ld	(MsgDriveLet), a
	ld	a, '/'
	ld	(MsgDriveLet+1), a
	
	ld	hl, MsgDrive
	ld	de, LST_DISK_INFO + 1 << 8	
	call	PrintStr	
		
	ld	hl, (AUCntUsed)
	rl	l							;*2, 2K/AU
	rl	h
	ld	de, MsgFilesCntNo+2
	call	Word2Txt	
	ld	a, (MsgFilesCntNo+6)
	or	$80
	ld	(MsgFilesCntNo+6), a
	ld	a, '/'
	ld	(MsgFilesCntNo+3), a
	
	ld	a, (FileCnt)
	ld	l, a
	ld	h, 0
	ld	de, MsgFilesCntNo
	call	Byte2Txt	
	ld	hl, MsgFilesCnt
	ld	de, LST_DISK_INFO + 2 << 8
	call	PrintStr	

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcFileCache:
	ld	a, (SelFile)
	ld	de, CACHE_SZ
	call	Mul
	ld	bc, FileCache
	add		hl, bc				;HL = file AU cnt
	ld	(SelFileCache), hl
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ReadKeyLoop:
	call	CalcFileCache
	call	DisplayFileInfo

	call	ReadChar	

	cp	KEY_DOWN
	jr	z,  DoKeyDown
	cp 	'a'
	jr	nz, CheckUp

DoKeyDown:
	ld	a, (FileCnt)
	ld	b, a
	ld	a, (SelFile)
	inc	a
	cp	b
	jr	nc, ReadKeyLoop
	ld	(SelFile), a
	jp	MoveIt

CheckUp:
	cp	KEY_UP
	jr	z, DoKeyUp
	cp 	'q'
	jr	nz, CheckRight

DoKeyUp:
	ld	a, (SelFile)
	or	a
	jr	z, ReadKeyLoop

	dec	a
	ld	(SelFile), a
	jp	MoveIt

CheckRight:
	cp	KEY_RIGHT
	jr	z, DoKeyRight
	cp 	'p'
	jr	nz, CheckLeft

DoKeyRight:
	ld	a, (FileCnt)
	ld	b, a
	ld	a, (SelFile)
	add	LST_LINES_CNT
	cp	b
	jr	nc, ReadKeyLoop

	ld	(SelFile), a
	jp	MoveIt

CheckLeft:
	cp	KEY_LEFT
	jr	z, DoKeyLeft
	cp	'o'
	jr	nz, CheckEnter

DoKeyLeft:
	ld	a, (SelFile)
	sub	LST_LINES_CNT
	jr	c, ReadKeyLoop

	ld	(SelFile), a
	jp	MoveIt

CheckEnter:
	cp	KEY_ENTER
	jr	z, DoKeyEnter
	cp	'm'
	jp	nz, CheckKeyInfo
	
DoKeyEnter:	
	call	HandleFile
	jp	HCRunMain

CheckKeyInfo:
	cp	'4'
	jr	nz, CheckKeyCopy
	
	ld	a, (FileCnt)
	or	a
	jp	z, ReadKeyLoop
	
	ld	ix, (SelFileCache)
	ld	hl, MsgReadingExt
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadFileHeader
	ld	b, 1
	call	ClearNMsgLines
	jp	ReadKeyLoop
	
CheckKeyCopy:
	cp	'5'
	jp	nz, CheckKeyFileInfo
	
	ld	a, (FileCnt)
	or	a
	jp	z, ReadKeyLoop	
			
	ld	hl, (SelFileCache)
	call	CopyFile		
	ld	a, (CopyFileRes)
	or	a
	jr	z, CopyFileOK
	
	ld	l, a
	ld	h, 0
	ld	de, MsgErrCode
	call	Byte2Txt
	ld	hl, MsgErr
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar
	jp	ReadKeyLoop
	
CopyFileOK:		
	ld	b, 2
	call	ClearNMsgLines
	;Display destination disk after file copy, if on disk copy, to to COM (1, 2, 4).
	ld	a, (CopySelOption)
	cp	'3'
	jp	z, ReadKeyLoop
	ld	a, (CopyFileDstDrv)	
	dec	a
	ld	(RWTSDrive), a
	call	BDOSSelectDisk	;Select destination disk after copy, to show the new file list.
	jp	HCRunInitDisk

CheckKeyFileInfo:
	cp	' '
	jr	nz, CheckKeyDriveA
	
	ld	a, (FileCnt)
	or	a
	jp	z, ReadKeyLoop
	
	call	ReadAllHeaders
	jp	ReadKeyLoop

CheckKeyDriveA:
	cp	'1'
	jr	nz, CheckKeyDriveB
	ld	a, DRIVE_A_CPM
	jp	SelectDrive
	
CheckKeyDriveB:
	cp	'2'
	jr	nz, CheckKeyView
	ld	a, DRIVE_B_CPM
	jp	SelectDrive
	
CheckKeyView:
	cp	'3'
	jr	nz, CheckKeyRename
	
	ld	a, (FileCnt)
	or	a
	jp	z, ReadKeyLoop
	

	ld	hl, MsgViewFileMenu
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	ld	hl, MsgViewFileText
	ld	de, LST_LINE_MSG + 2 << 8
	call	PrintStr
	ld	hl, MsgViewFileHex
	ld	de, LST_LINE_MSG + 3 << 8
	call	PrintStr
	ld	hl, MsgViewFileAuto
	ld	de, LST_LINE_MSG + 4 << 8
	call	PrintStr
	call	ReadChar

	call	ViewFile
	jp	HCRunMain
	
CheckKeyRename:
	cp	'6'
	jr	nz, CheckKeyDel
	
	ld	a, (FileCnt)
	or	a
	jp	z, ReadKeyLoop
	
	ld	hl, MsgNewFileName
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	
	ld	hl, MsgClear
	ld	de, FileData
	ld	bc, NAMELEN
	ldir
	ld	a, $80 | ' '
	ld	(de), a
	ld	de, LST_LINE_MSG + 2 << 8
	ld	hl, FileData
	call	PrintStr
	
	ld	de, LST_LINE_MSG + 2 << 8
	ld	bc, NAMELEN
	call	ReadString
	
	ld	de, FileData
	ld	a, (de)
	cp		' '				;If starting with space, input was canceled.
	jp	z, RenameCanceled
	
	;Check if new name doesn't exist already. Cancel if so.
	ld	de, FileData
	call	DoesFileExistInCache
	jr	nz, RenameFileNotExist

	ld	hl, MsgFileExists
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar
	jr	RenameCanceled
	
RenameFileNotExist:	
	ld	de, FileData
	ld	hl, (SelFileCache)
	call	RenameFile
	jp	HCRunInitDisk
	
RenameCanceled:
	ld	b, 2
	call	ClearNMsgLines
	jp	ReadKeyLoop
	
CheckKeyDel:
	cp	'8'
	jr	nz, CheckKeyAttrib
	
	ld	a, (FileCnt)
	or	a
	jp	z, ReadKeyLoop
	
	ld	hl, MsgDelete
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar
	cp	'y'
	jr	z, DoFileDelete
	ld	b, 1
	call	ClearNMsgLines
	jp	ReadKeyLoop
DoFileDelete:	
	ld	hl, (SelFileCache)
	ld 	a, (RWTSDrive)
	inc		a				;Convert to BASIC drive number: 1,2
	call	DeleteFile
	jp	HCRunInitDisk
	
CheckKeyAttrib:
	cp	'7'
	jr	nz, CheckKeyDiskMenu
	
	ld	a, (FileCnt)
	or	a
	jp	z, ReadKeyLoop
	
	ld	hl, MsgSetRO
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar
	ld	e, 0
	cp	'y'	
	jr	nz, CheckSYS
	ld	e, 1

CheckSYS:	
	push	de
		ld	hl, MsgSetSYS
		ld	de, LST_LINE_MSG + 2 << 8
		ld	a, SCR_DEF_CLR | CLR_FLASH
		call	PrintStrClr
		call	ReadChar
		cp	'y'
	pop	de
	jr	nz, AttrChange
	ld	a, %10
	or	e
	ld	e, a
	
AttrChange:		
	ld	hl, (SelFileCache)
	call	ChangeFileAttrib
	jp	HCRunInitDisk	
	
SelectDrive:
	ld 	(RWTSDrive), a	
	call	BDOSSelectDisk
	;call	BDOSInit		
	jp	HCRunInitDisk
	
CheckKeyDiskMenu:
	cp	'9'
	jp	nz, CheckKeyExit	
		
	ld	a, (RWTSDrive)
	add	'A'	
	;Update menu messages with current drive.
	ld	(MsgMenuSingleDrv1), a
	ld	(MsgMenuSingleDrv2), a
	ld	(MsgMenuDualDrv1), a	
	ld	(MsgMenuToComDrv), a
	ld	(MsgMenuFromCOMDrv), a		
	;Update menu messages with the alternate drive.
	ld	a, (RWTSDrive)
	inc	a
	xor	%11
	add	'A'-1
	ld	(MsgMenuDualDrv2), a
	
	ld	hl, MsgMenuDiskCopy
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	ld	hl, MsgMenuBack
	ld	de, LST_LINE_MSG + 2 << 8
	call	PrintStr		
	ld	hl, MsgMenuSingle
	ld	de, LST_LINE_MSG + 3 << 8
	call	PrintStr	
	ld	hl, MsgMenuDual
	ld	de, LST_LINE_MSG + 4 << 8
	call	PrintStr	
	ld	hl, MsgMenuToCOM
	ld	de, LST_LINE_MSG + 5 << 8
	call	PrintStr
	ld	hl, MsgMenuFromCOM
	ld	de, LST_LINE_MSG + 6 << 8
	call	PrintStr		
	ld	hl, MsgMenuFmt1
	ld	de, LST_LINE_MSG + 7 << 8
	call	PrintStr
	ld	hl, MsgMenuFmt2
	ld	de, LST_LINE_MSG + 8 << 8
	call	PrintStr
	
	call	ReadChar
	push	af
		ld	b, 8
		call	ClearNMsgLines
	pop	af
	ld	(CopySelOption), a

CheckKeyDiskMenuLoop:	
	cp	'0'
	jp	z, DiskMenuExit
	
	;Single drive copy
	cp	'1'
	jr	nz, CheckDiskMenuDualDrive	
	call	CopyDisk
	ld	b, 2
	call	ClearNMsgLines
	jp	DiskMenuExit
	
	;Dual drive copy
CheckDiskMenuDualDrive:	
	cp	'2'
	jr	nz, CheckDiskMenuToCOM	
	call	CopyDisk
	ld	b, 2
	call	ClearNMsgLines
	jr	DiskMenuExit

CheckDiskMenuToCOM:	
	cp	'3'
	jr	nz, CheckDiskMenuFromCOM
	call	CopyDiskToCOM
	jr	DiskMenuExit
	
CheckDiskMenuFromCOM:	
	cp	'4'
	jr	nz, CheckDiskMenuFormat1
	call	CopyDiskFromCOM
	jp	HCRunInitDisk
	
CheckDiskMenuFormat1:
	cp	'5'
	jp	nz, CheckDiskMenuFormat2
	
	ld	a, DRIVE_A_CPM
	ld	(RWTSDrive), a	
	ld	hl, MsgMenuFmt1+3
	jr	FormatDiskAction
	
CheckDiskMenuFormat2:
	cp	'6'
	jp	nz, HCRunMain
	
	ld	a, DRIVE_B_CPM
	ld	(RWTSDrive), a	
	ld	hl, MsgMenuFmt2+3
	
FormatDiskAction:		
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	
	ld	hl, MsgAreYouSure
	ld	de, LST_LINE_MSG + 2 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar
	cp	'y'
	jp	nz, HCRunMain
	
	ld	hl, MsgClear
	ld	de, LST_LINE_MSG + 2 << 8
	ld	a, SCR_DEF_CLR
	call	PrintStrClr

	call	FormatDisk
	or	a
	jp	z, HCRunInitDisk

	;Display error for format
	ld	l, a
	ld	h, 0
	ld	de, MsgErrCode
	call	Byte2Txt
	ld	hl, MsgErr
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar
	jp	HCRunInitDisk

DiskMenuExit:
	jp	ReadKeyLoop

CheckKeyExit:
	cp	'0'
	jp	nz, ReadKeyLoop
	jp	HCRunEnd
	;jp		0				;Had to exit by reset, since after doing CLEAR in unpack.asm, we can't return to BASIC as before.

MoveIt:
	call 	MoveCursor
	jp	ReadKeyLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


DisplayFilename:
	LD	B, NAMELEN
DispLoop:
	LD	A, (DE)

	;clear bit 7
	RES 	7, A
	LD	(CODE), A

	INC	DE
	PUSH	DE
	PUSH	BC
		CALL	PrintChar
	POP	BC
	POP 	DE

	LD	HL, COL
	INC	(HL)
	DJNZ	DispLoop
	;now a name is displayed

	;check bounds
	LD	A, (LINE)
	INC	A
	CP	LST_LINES_CNT + LST_FIRST_LINE
	JR	C, LineOK

	;set names column to the next one
	LD	A, (NameCol)
	ADD	NAMELEN + 1
	LD	(NameCol), A

	LD	A, LST_FIRST_LINE
LineOK:
	LD	(LINE), A

	LD	A, (NameCol)
	LD	(COL), A

	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisplayFilenames:		
	ld	de, (LST_FIRST_LINE << 8) | LST_FIRST_COL + 1
	ld	(LineCol), de	

	ld	de, FileCache
	ld	a, (FileCnt)
	or	a
	ret	z
	
	ld	b,	a

DisplayFilenamesLoop:
	push	bc
		push	de
		call	DisplayFilename
		pop	de
		ex	de, hl
		ld	bc, CACHE_SZ
		add	hl, bc
		ex	de, hl
	pop	bc
	djnz	DisplayFilenamesLoop

	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Selects only valid filenames (not deleted and only from first extension)
GetFileNames:
	ld	ix, TrackBuf
	ld	de, FileCache
	ld	b, MAX_EXT_CNT
	xor	a
	ld	(FileCnt), a
	ld	hl, AUCntUsed
	ld	(hl), a
	inc	hl
	ld	(hl), a

StoreFilenamesLoop:
	xor a
	cp (ix + EXT_DEL_FLAG)
	jp nz, NextExt		

	;count AU
	exx
	push hl
		call CheckExtAlloc
		ex de, hl		;save first AU no.

		;store disk alocated AU count
		ld hl, (AUCntUsed)
		ld c, b
		ld b, 0
		add hl, bc
		ld (AUCntUsed), hl
	pop hl
	exx

	xor	a
	cp (ix + EXT_IDX)	;check if first extension
	jr nz, FindExt

	push ix
	pop hl
	inc hl				;skip del flag

	push bc
		ld bc, NAMELEN
		ldir			;save file name

		exx
		push 	de		;de = first AU
		exx
		pop	hl
		ex	de, hl
		ld	(hl), e
		inc	hl
		ld		(hl), d	;save first AU
		
		inc	hl

		exx				;save AU cnt for file
		push	bc
		exx
		pop	bc
		ld	(hl), c
		inc	hl
		ld	(hl), b
		inc	hl

		;xor		a		;make flag 0 to signal that header is not read yet
		;ld	(hl), a

		ld	bc, HDR_SZ + 1
		add	hl, bc

		ex	de, hl
	pop bc


	ld 		a, (FileCnt)		;inc file counter
	inc	a
	ld 	(FileCnt), a
	cp	LST_MAX_FILES
	jr	c, NextExt
	jr	GetFileNamesEnd


FindExt:				;BC' = AU cnt for this ext
	push	bc
		push 	de
		push	ix
			pop	de
			inc	de			;DE = name to find

			ld	hl, FileCache
			ld	a, (FileCnt)
			ld	c, a
			ld	b, 0
			call	FindCache
			jr	nz, FindExtEnd

			ld	bc, CACHE_AU_CNT
			add	hl, bc
		exx
		push	bc
		exx
			pop	bc

			ld		e, (hl)	;DE = Current AU CNT for file
			inc	hl
			ld	d, (hl)
			dec	hl
			ex	de, hl
			add	hl, bc
			ex	de, hl
			ld	(hl), e
			inc	hl
			ld	(hl), d
			dec	hl
FindExtEnd:
		pop	de
	pop	bc

NextExt:
	push bc
		ld bc, EXT_SZ
		add ix, bc
	pop	bc

	dec	b
	ld	a, b
	or	a
	jp	nz, StoreFilenamesLoop
GetFileNamesEnd:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Take care of file depeding on file type: run programs, display SCREEN$, load code
;IN: HL = file name
HandleFile:
	;Make HL point to the selected file
	ld	ix, (SelFileCache)
	push	ix
		ld	a, (ix + CACHE_FLAG)
		or	a
		call	z, ReadFileHeader

		ld	a, (ix + CACHE_HDR + HDR_TYPE)
		cp	PROG_TYPE
		jr	z, HandleFileProg

		cp	BYTE_TYPE
		jr	nz, HandleFileText

		ld	l, (ix + CACHE_HDR + HDR_LEN)	;get length
		ld	h, (ix + CACHE_HDR + HDR_LEN + 1)
		ld	de, -SCR_LEN		;check if the length is for a screen$ file
		add	hl, de
		ld	a, h
		or	l
		jr	z, HandleFileSCR


HandleFileCODE:
		ld	hl, MsgLoadingCODE
		ld	de, LST_LINE_MSG+1 << 8
		ld	a, SCR_DEF_CLR | CLR_FLASH
		call	PrintStrClr

		;Copy file load function to printer buffer to not be overwritten by CODE block.
		ld	hl, IF1FileLoad
		ld	de, PRN_BUF
		ld	bc, IF1FileLoadEnd - IF1FileLoad
		ldir
	pop	hl
	ld	de, (DataBuf + HDR_ADDR)	;get CODE start address to load to and then execute
	pop	bc					;balance stack to exit to BASIC after CODE returns - 1 call for this function
	pop	bc					;2nd, 3rd call for error handler
	pop	bc
	ld	(ERRSP), bc
	push	de					;push CODE address to return to = start of CODE block
	jp	PRN_BUF




HandleFileSCR:
		ld	hl, MsgLoadingSCR
		ld	de, LST_LINE_MSG+1 << 8
		ld	a, SCR_DEF_CLR | CLR_FLASH
		call	PrintStrClr

	pop	hl
	
	IFDEF _REAL_HW_
		;Load to alternate SCREEN$ memory
		ld	de, HC_VID_ADDR_C000
		call	IF1FileLoad
		
		;Set display to alternate SCREEN$ memory
		ld	a, HC_CFG_VID_C000
		out 	(HC_CFG_PORT), a
		
		call	ReadChar
		
		;Set back to regular SCREEN$ memory
		ld	a, HC_CFG_VID_4000
		out 	(HC_CFG_PORT), a	
	ELSE
		ld	de, HC_VID_ADDR_4000
		call	IF1FileLoad		
		
		call	ReadChar
	ENDIF
	
	ret

HandleFileProg:
		ld	hl, MsgLoadingPrg
		ld	de, LST_LINE_MSG+1 << 8
		ld	a, SCR_DEF_CLR | CLR_FLASH
		call	PrintStrClr
	pop	hl
	call	LoadProgram
	ret


HandleFileText:
	pop	hl	
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

;Use constants for loading in RAM only as much as we can in order to fit both the binary and the text representation.
ViewFileConvertRatioText	EQU	1			;Text data is stored as is, 1:1, byte to byte.
ViewFileConvertRatioBASIC	EQU	2			;BASIC tokens are expanded to text as 1 byte to 2 chars on average. Fits about 6KB of compiled BASIC. Viewing larger files might cause crash.
ViewFileConvertRatioHEX		EQU	5			;1 byte expands to 4 bytes when printed as hex. So RAM stores 1+4 bytes for each byte.
ViewFileConvertRatioASM		EQU	3			;Disassembly is expanded as 1:3? To test!

;Auto viewing mode will show content bases on file type: no type - as text, programs as BASIC, rest - as hex
;Skip header, if exists.

ViewFile:
	ld	hl, 0
	ld	(FilePosRead), hl
	ld	(ViewSelOption), a
	xor	a
	ld	(ViewFilePart), a
	ld	ix, FileBlocksIdx
	ld	hl, 0
	ld	(ix), l
	ld	(ix+1), h
	ld	(FileBlocksIdxPos), ix
	
	;Read file header if not yet read.
	ld	ix, (SelFileCache)
	ld	a, (ix + CACHE_FLAG)
	or	a
	call	z, ReadFileHeader
	
ViewFileNextBlock:		
	ld	a, (ViewSelOption)
	
	cp	'1'
	jr	z, ViewFileAsText

	cp	'2'
	jr	z, ViewFileAsHex

ViewFileAuto:
	;Decide how to display file, if auto mode.
	ld	ix, (SelFileCache)
	ld	a, (ix + CACHE_HDR + HDR_TYPE)
	cp	PROG_TYPE	
	jr	z, ViewFileAsBASIC	
	
	cp	BYTE_TYPE
	jr	z, ViewFileAsHex
	
ViewFileAsText:
	;If text file, load as much as possible to RAM.
	ld	b, MAX_SECT_BUF * ViewFileConvertRatioText
	call	ReadFileForViewing	
	jp	ViewFileText
	
ViewFileAsHex:
	ld	b, MAX_SECT_BUF/ViewFileConvertRatioHEX
	call	ReadFileForViewing
	ld	de, FileData + MAX_SECT_BUF*SECT_SZ/ViewFileConvertRatioHEX
	push	de	
		call	Bin2HexStr		
	pop	hl
	;Determine lenght of hex print buffer.
	ex	de, hl
	or	a
	sbc	hl, de
	ld	b, h
	ld	c, l
	ex	de, hl
	jr	ViewFileText
	
	
ViewFileAsBASIC:		
	ld	b, MAX_SECT_BUF/ViewFileConvertRatioBASIC	;Load half of available RAM with program bytecode, leave half for decoded text.
	call	ReadFileForViewing							
	;Read program length from header. Skip file header.
	ld	bc, HDR_SZ
	add	hl, bc
	ld	ix, (SelFileCache)
	ld	c, (ix + CACHE_HDR + HDR_PLEN)
	ld	b, (ix + CACHE_HDR + HDR_PLEN + 1)
	ld	de, FileData + MAX_SECT_BUF*SECT_SZ/ViewFileConvertRatioBASIC	;Store text of program after read block.
	push	de	
		call	BASIC2TXT		
	pop	de	
	;Get decoded text length	
	ld	hl, (DestinationAddr)		
	or	a
	sbc	hl, de
	ld	b, h
	ld	c, l
	ex	de, hl
	
ViewFileText:	
	push	hl
	push	bc
		call	ClrScr	
	pop	bc
	pop	hl
	push	hl
		call	TextViewer	
	pop	hl
	
ViewFileTextLoop:	
	ld	a, (LAST_K)
	
	cp	'0'
	ret	z
	
	cp	KEY_UP
	jr	nz, ViewFileTextLoopDown
	
	ld	a, (ViewFilePart)
	or	a
	jr	z, ViewFileTextLoop
	
	dec	a
	ld	(ViewFilePart), a
	
	;Go back 1 block index.
	ld	ix, (FileBlocksIdxPos)
	dec	ix
	dec	ix
	ld	l, (ix)
	ld	h, (ix+1)
	ld	(FilePosRead), hl
	ld	(FileBlocksIdxPos), ix
	jp	ViewFileNextBlock
	
	
ViewFileTextLoopDown:	
	cp	KEY_DOWN
	jr	nz, ViewFileTextLoop
	
	ld	hl, ViewFilePart
	inc	(hl)	
		
	;Save file index for when scrolling back.
	ld	ix, (FileBlocksIdxPos)
	inc	ix
	inc	ix
	ld	hl, (FilePosRead)
	ld	(ix), l
	ld	(ix+1), h	
	ld	(FileBlocksIdxPos), ix
	jp	ViewFileNextBlock
	

;Reads file section, as much as it fits in RAM for the type of output.
;Returns HL=start address and BC=length read.
;IN: B = how many sectors to read.
ReadFileForViewing:
	ld	hl, (SelFileCache)	
	ld	a, b
	ld	(ViewSectMax), a
	ld 	a, (RWTSDrive)
	inc	a
	call		ReadFileSection	;DE = last address read

	;Calculate size of read buffer.
	push	de
		ld	hl, FileData
		ex	de, hl
		or	a
		sbc	hl, de
		ld	b, h
		ld	c, l
	pop	de
	
	;Check file type from header, to see if header exists or not.
	ld	ix, (SelFileCache)	
	ld	a, (ix + CACHE_HDR + HDR_TYPE)
	cp	TEXT_TYPE	
	jr	c, ReadFileForViewingNotText
	
	;Find EOF for text files and ajust lenght.
	ld	hl, FileData
	ld	d, b
	ld	e, c
	ld	a, CHAR_EOF
	cpir
	jr	nz, ReadFileForViewingNotFoundEOF
	inc	bc
ReadFileForViewingNotFoundEOF:	
	or	a
	ex	hl, de
	sbc	hl, bc
	ld	b, h
	ld	c, l

ReadFileForViewingNotText:	
	ld	hl, FileData
	ret
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


DisplayFileInfo:
	ld	hl, (SelFileCache)
	push	hl
		;disk size - at least 2KB ==1  AU
		ld	bc, CACHE_AU_CNT
		add	hl, bc
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		dec	hl
		ex		de, hl			
		;*2, since one block (AU) is 2KB.
		rl	l
		rl	h

		ld	de, MsgFileSzDskN
		call	Word2Txt
		ld	hl, MsgFileSzDsk
		ld	de, LST_FILE_INFO + 1 << 8
		call	PrintStr
	pop	hl
	push	hl
		;attributes
		ld	bc, CACHE_NAME + RO_POS
		add	hl, bc
		ex	de, hl
		ld	hl, MsgFileAttrN
		ld	a, (de)
		and	%10000000
		jr	z, NotRO

		ld	bc, '/R'
		ld	(hl), c
		inc	hl
		ld	(hl), b
		inc	hl
		ld	bc, ',O'
		ld	(hl), c
		inc	hl
		ld	(hl), b
		inc	hl
		jr	CheckSys
NotRO:
		ld	bc, '--'
		ld	(hl), c
		inc	hl
		ld	(hl), b
		inc	hl
		ld	bc, ',-'
		ld	(hl), c
		inc	hl
		ld	(hl), b
		inc	hl

CheckSys:
		inc	de
		ld	a, (de)
		and	%10000000
		jr	z, NotSYS

		ld	bc, 'IH'
		ld	(hl), c
		inc	hl
		ld	(hl), b
		inc	hl
		ld	a, 'D' + $80
		ld	(hl), a
		jr	AttrEnd
NotSYS:
		ld	bc, '--'
		ld	(hl), c
		inc	hl
		ld	(hl), b
		inc	hl
		ld	a, '-' + $80
		ld	(hl), a
AttrEnd:
		ld	de, LST_FILE_INFO + 2 << 8
		ld	hl, MsgFileAttr
		call	PrintStr
	pop	ix
	push	ix
		ld	a, (ix + CACHE_FLAG)
		or	a
		jp	z, HeadNotRead

		ld	a, (ix + CACHE_FIRST_AU)
		or	(ix + CACHE_FIRST_AU + 1)
		jp	z, HeadNotRead		

		ld	a, (ix + CACHE_HDR)
		cp	PROG_TYPE
		jr	nz, CheckNoArr

		ld	hl, MsgFileTypePrg
		ld	de, MsgFileTypeN
		call	MoveMsg
		jr	PrepFileLen

CheckNoArr:
		cp	NUMB_TYPE
		jr	nz, CheckChrArr

		ld	hl, MsgFileTypeNoA
		ld	de, MsgFileTypeN
		call	MoveMsg
		jr	PrepFileLen

CheckChrArr:
		cp	CHAR_TYPE
		jr	nz, CheckByte

		ld	hl, MsgFileTypeChrA
		ld	de, MsgFileTypeN
		call	MoveMsg
		jr	PrepFileLen

CheckByte:
		cp	BYTE_TYPE
		jr	nz, CheckText

		ld	l, (ix + CACHE_HDR + HDR_LEN)
		ld	h, (ix + CACHE_HDR + HDR_LEN + 1)
		ld	bc, -SCR_LEN
		add	hl, bc
		ld	a, h
		or	l
		jr	nz, NotScr

		ld	hl, MsgFileTypeSCR
		ld	de, MsgFileTypeN
		call	MoveMsg
		jr	PrepFileLen
NotScr:
		ld	hl, MsgFileTypeByte
		ld	de, MsgFileTypeN
		call	MoveMsg
		jr	PrepFileLen

CheckText:
		ld	hl, MsgFileTypeText
		ld	de, MsgFileTypeN
		call	MoveMsg				

PrepFileLen:
		;File len
		ld	l, (ix + CACHE_HDR + HDR_LEN)
		ld	h, (ix + CACHE_HDR + HDR_LEN + 1)
PrepFileLenText:		
		ld	de, MsgFileLenN
		call	Word2Txt
		ld	h, 'B' | $80
		ld	l, ' '
		ld	(MsgFileLenN + 5), hl

		ld	a, (ix + CACHE_HDR + HDR_TYPE)
		cp	PROG_TYPE
		jr	z, PrintProgStart

		cp	BYTE_TYPE
		jr	z, PrintByteStart		
		
		jr	PrintStartNotRead

PrintProgStart:
		ld	l, (ix + CACHE_HDR + HDR_LINE)
		ld	h, (ix + CACHE_HDR + HDR_LINE + 1)
		jr	PrintStart

PrintByteStart:
		ld	l, (ix + CACHE_HDR + HDR_ADDR)
		ld	h, (ix + CACHE_HDR + HDR_ADDR + 1)
		jr	PrintStart

HeadNotRead:
		ld        hl, MsgNA
		ld        de, MsgFileTypeN
		call    MoveMsg		
		
		ld	hl, MsgNA
		ld	de, MsgFileLenN
		call	MoveMsg
		
PrintStartNotRead:
		ld	hl, MsgNA
		ld	de, MsgFileStartN
		call	MoveMsg
		jr	PrintStartStr

PrintStart:
		ld	e, ' '
		ld	d, ' ' | $80
		ld	(MsgFileStartN + 5), de
		ld	de, MsgFileStartN
		call	Word2Txt
PrintStartStr:
		ld	de, LST_FILE_INFO + 4 << 8
		ld	hl, MsgFileStart
		call	PrintStr

	pop	ix
	ld	de, LST_FILE_INFO + 3 << 8
	ld	hl, MsgFileType
	call	PrintStr

	ld	de, LST_FILE_INFO + 5 << 8
	ld	hl, MsgFileLen
	call	PrintStr

	ret

MoveMsg:
	ld	bc, 7
	ldir
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadAllHeaders:
	ld	hl, MsgReadingExt
	ld	de, LST_LINE_MSG+1 << 8
	ld	a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr

	call	CalcFileCache

	ld	a, (SelFile)
	ld	b, a
	ld	a, (FileCnt)
	sub	b
	or	a
	ret	z

	ld	b, a

	ld	ix, (SelFileCache)
NextFile:
	push	bc
		call	ReadFileHeader
		ld	bc, CACHE_SZ
		add	ix, bc
		push	ix
		call	CalcFileCache
		call	DisplayFileInfo
		pop	ix

		call	KbdHit
		jr	c, AKey
	pop	bc
	jr	ReadAllHeadersEnd

AKey:
		ld	a, (SelFile)
		inc	a
		ld	b, a
		ld	a, (FileCnt)
		cp	b
		jr	z, DontInc
		ld	a, b
		ld	(SelFile), a
		call	MoveCursor
	pop	bc
	djnz	NextFile

ReadAllHeadersEnd:
	ld	b, 1
	call	ClearNMsgLines
	ret

DontInc:
	pop	bc
	jr	ReadAllHeadersEnd
		
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	include "hccfg.asm"
	include "if1.asm"
	include "bdos.asm"	
	include "ui.asm"
	include "math.asm"	
	include "txtview.asm"	
	include "serial.asm"
	include "bas2txt.asm"	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VerMsg1		DEFM	'HCCmd ', __DATE__
VerMsg2		DEFM	'George Chirtoac', 'a' + $80
MsgSysInf	DEFM	'Program Info   ', ' ' + $80
MsgDskInf	DEFM	'Disk Info      ', ' ' + $80
MsgFileInf	DEFM	'File Info      ', ' ' + $80
MsgMessages	DEFM	'Messages       ', ' ' + $80
BtnBar		DEFM	'1-A:|2-B:|3-View|4-Prop|5-Copy|6-Ren|7-Attr|8-Del|9-Disk|0-Exi', 't' + $80
MsgDrive	DEFM	'Drv/Free:  '
MsgDriveLet	DEFM	'A', '/'
MsgFreeSpaceNo	DEFM	'000'
MsgFilesCnt	DEFM	'Files/KB:'
MsgFilesCntNo	DEFM	'000/000'
MsgErr		DEFM	'Error code '
MsgErrCode	DEFM	'000',' ' + $80
MsgLoadingPrg	DEFM	'Loading Progra', 'm' + $80
MsgLoadingSCR	DEFM	'Loading SCREEN', '$' + $80
MsgLoadingCODE	DEFM	'Loading CODE (!', ')' + $80
MsgFileSzDsk	DEFM	'Disk Len:'
MsgFileSzDskN	DEFM	'00000 ', 'K' + $80
MsgFileAttr	DEFM	'Attrib  :'
MsgFileAttrN	DEFM	'R/O,HI', 'D' + $80
MsgFileType	DEFM	'Type    :'
MsgFileTypeN	DEFM	'         ', ' ' + $80
MsgFileTypePrg	DEFM	'Progra', 'm' + $80
MsgFileTypeByte	DEFM	'Bytes ', ' ' + $80
MsgFileTypeSCR	DEFM	'SCREEN', '$' + $80
MsgFileTypeChrA	DEFM	'Chr.Ar', 'r' + $80
MsgFileTypeNoA	DEFM	'No. Ar', 'r' + $80
MsgFileTypeText	DEFM	'Untype', 'd' + $80
MsgNA		DEFM	'N/A   ', ' ' + $80
MsgFileLen	DEFM	'Length  :'
MsgFileLenN	DEFM	'65535 ', 'B' + $80
MsgFileStart	DEFM	'Start   :'
MsgFileStartN	DEFM	'65535 ', ' ' + $80
MsgReadingExt	DEFM	'Reading heade', 'r' | $80
MsgClear	DEFM	'               ', ' ' | $80
MsgDelete	DEFM	'Del file? y/', 'n' | $80
MsgSetRO	DEFM	'Set R/O? y/', 'n' | $80
MsgSetSYS	DEFM	'Set HID? y/', 'n' | $80
MsgNewFileName	DEFM	'Name?none=abort', ':' | $80
MsgMenuDiskCopy	DEFM	'Disk menu', ':' | $80
MsgMenuFileCopy	DEFM	'File copy menu', ':' | $80
MsgMenuBack	DEFM	'0. Exit men', 'u' | $80

MsgMenuSingle	DEFM	'1. Copy '
MsgMenuSingleDrv1	DEFM	'A:->'
MsgMenuSingleDrv2	DEFM	'A', ':' | $80

MsgMenuDual	DEFM	'2. Copy '
MsgMenuDualDrv1	DEFM	'A:->'
MsgMenuDualDrv2	DEFM	'B', ':' | $80

MsgMenuToCOM	DEFM	'3. Copy '
MsgMenuToComDrv	DEFM	'A:->CO', 'M' | $80

MsgMenuFromCOM		DEFM	'4. Copy COM->'
MsgMenuFromCOMDrv	DEFM	'A', ':' | $80

MsgMenuFromTape		DEFM	'5. Copy Tape->'
MsgMenuFromTapeDrv	DEFM	'A', ':' | $80

;MsgMenuToTape		DEFM	'6. Copy '
;MsgMenuToTapeDrv	DEFM	'A:->Tap', 'e' | $80

MsgMenuFmt1	DEFM	'5. Format A', ':' | $80
MsgMenuFmt2	DEFM	'6. Format B', ':' | $80

MsgBlocksLeft	DEFM	'000 blocks lef', 't' | $80
MsgFileOverwrite	DEFM	'Overwrite? y/', 'n' | $80
MsgFileExists	DEFM	'File name exist', 's' | $80
MsgInsertSrcDsk	DEFM	'Put SOURCE dis', 'k' | $80
MsgInsertDstDsk	DEFM	'Put DEST. disk', ' ' | $80
MsgPressAnyKey	DEFM	'Press any ke', 'y' | $80
MsgCopySectors	DEFM	'000 sectors cop', 'y' | $80
MsgAreYouSure	DEFM	'Are you sure?y/', 'n' | $80
MsgViewFileMenu	DEFM	'View file menu', ':' | $80
MsgViewFileText	DEFM	'1.As tex', 't' | $80
MsgViewFileHex	DEFM	'2.As he', 'x' | $80
MsgViewFileAuto	DEFM	'3.Auto-1/2/BASI', 'C' | $80

MsgTapeLoadErr		DEFM	'Tape load erro', 'r' | $80
MsgErrFileTooBig	DEFM	'File too bi', 'g' | $80
MsgFileName		DEFM	'Name: '
MsgFileNameN		DEFM	'          '

	IFNDEF	_REAL_HW_
FontTable:	
	incbin "cpmfnt.bin"
	ENDIF
EndCode:

;Unalocated variables
UnallocStart		EQU	VAR_START
FileCnt			EQU	UnallocStart		;File counter, 1B
NameCol			EQU	FileCnt + 1			;Column for file name, 1B
SelFile			EQU	NameCol + 1 		;Selected file using cursor, 1B
CursorAddr		EQU	SelFile + 1			;2 B
AUCntUsed		EQU	CursorAddr + 2		;2 B
AUCntMaxFree		EQU	AUCntUsed + 2		;2 B
SelFileCache		EQU	AUCntMaxFree + 2	;2 B
CopySelOption		EQU	SelFileCache+2		;1 B
ViewSelOption		EQU	CopySelOption + 1
ViewSectMax		EQU	ViewSelOption + 1
ViewFilePart		EQU	ViewSectMax+1
FileBlocksIdxPos	EQU	ViewFilePart+1

CopyFileFCB		EQU	FileBlocksIdxPos + 2
CopyFileRes		EQU	CopyFileFCB + 2
CopyFileDMAAddr		EQU	CopyFileRes + 1
FilePosRead		EQU	CopyFileDMAAddr + 2
FilePosWrite		EQU	FilePosRead + 2
CopyFileSectCnt		EQU	FilePosWrite + 2
CopyFileSrcDrv		EQU	CopyFileSectCnt + 1
CopyFileSrcName		EQU	CopyFileSrcDrv + 1
CopyFileDstDrv		EQU	CopyFileSrcName + 11
CopyFileDstName		EQU	CopyFileDstDrv + 1

FileCache		EQU	CopyFileDstName + 11			;cache table, size = 92 * 25 = 2300
;FS block list constants
UsedBlockListCnt	EQU	FileCache + LST_MAX_FILES*CACHE_SZ
UsedBlockListBlk	EQU	UsedBlockListCnt + 2
UsedBlockListSz		EQU	320 * 2 + 2						;640

	IFDEF	_REAL_HW_
FontTable		EQU	UsedBlockListCnt + UsedBlockListSz
DataBuf			EQU	FontTable + 872
	ELSE
DataBuf			EQU	UsedBlockListCnt + UsedBlockListSz
	ENDIF

TrackBuf		EQU	DataBuf	;size = 16 * 256 = 4096		


;File viewer constants
FileData		EQU	DataBuf
;4K index allows for 2000 lines of text.
FileIdxSize		EQU	4 * 1024
FileIdxBlocksSize	EQU	1 * 1024
;File buffer size, without index
FileDataSize		EQU	(MAX_SECT_RAM * SECT_SZ) - FileIdxSize - FileIdxBlocksSize
;Set a few KB aside for file indexing
FileIdx			EQU	FileData + FileDataSize
FileBlocksIdx		EQU	FileIdx + FileIdxSize
MAX_SECT_BUF		EQU	FileDataSize/SECT_SZ


;Copy buffer size, follows 
CopyDiskBuf		EQU DataBuf

;256 bytes for the stack should be enough.
MAX_RAM_FREE		EQU	$FF00 - DataBuf
MAX_AU_RAM		EQU	MAX_RAM_FREE/AU_SZ
MAX_SECT_RAM		EQU	MAX_RAM_FREE/SECT_SZ

	DISPLAY "DataBuf addr: ", /D,DataBuf
	DISPLAY "BinSize: ", /D, EndCode - Start
	DISPLAY "VarSize: ", /D, DataBuf - UnallocStart
	DISPLAY "MAX_RAM_FREE: ",/D,MAX_RAM_FREE		