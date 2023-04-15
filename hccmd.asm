	DEVICE ZXSPECTRUM48

RUN_ADDR		EQU	32768

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Define bellow is commented out to include the font binary in RAM, to make it work with Spectaculator HC-2000 emulator by Rares Atodiresei, which doesn't seem to implement the paging. 
;If not commented out, it will use the font table in the CPM ROM and the binary will be smaller.
	define  _ROM_FNT_
	
	org RUN_ADDR

Start:
	ifdef _ROM_FNT_				;If using the fonts from the CP/M ROM, must copy font table to buffer.
	call InitFonts
	endif
	call IF1Init

	;install error handler
	ld		hl, (ERRSP)
	push	hl
	ld		hl, ErrorHandler
	push	hl
	ld		(ERRSP), sp

HCRunInitDisk:	
	;Clear file cache
	ld		hl, UnallocStart
	ld		d, h
	ld		e, l
	inc		de
	ld		bc, TrackBuf - UnallocStart
	ld		(hl), 0
	ldir
	;Set track buffer to del marker
	ld		bc, SPT*SECT_SZ
	ld		(hl), DEL_MARKER
	ldir

	;main program
	call 	ReadCatalogTrack
	or		a					;Signal disk read error. On empty drive code 5 is shown.
	jr		z, HCRunMain
	
	ld		l, a
	ld		h, 0
	ld		de, MsgErrCode
	call	Byte2Txt
	ld		hl, MsgErr
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar
	ld		a, DRIVE_A_CPM		;Reset drive to A in case B was selected but was empty.
	ld		(RWTSDrive), a

HCRunMain:
	call 	InitUI
	call 	GetFileNames
	call	DisplayDiskInfo
	jp		ReadKeyLoop

HCRunEnd:
	;restore error handler
	pop		hl
	pop		hl
	ld		(ERRSP), hl

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ErrorHandler:
	pop		hl
	ld		(ERRSP), hl

	ld		a, (ERRNR)		;make something with the error code, display the error message maybe.
	ld		l, a
	ld		h, 0
	ld		de, MsgErrCode
	call	Byte2Txt
	ld		hl, MsgErr
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr

	ld		a, (ERRNR)
	call	GetErrMsg

	ld		hl, DataBuf
	ld		de, LST_LINE_MSG + 2 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr

	call	ReadChar
	jp	Start




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitUI:
	xor		a
	ld		(SelFile), A
	ld		(FileCnt), A
	ld		a, LST_FIRST_COL + 1
	ld		(NameCol), A

	ld		hl, SCR_BYTES_PER_LINE * LST_FIRST_LINE + LST_FIRST_COL/2
	ld		bc, (CurrScrAttrAddr)
	add		hl, bc
	ld		(CursorAddr), hl

	call	ClrScr

	ld		a, CHR_DC
	call	DrawVLines

	ld		a, SCR_LBL_CLR
	ld		de, 23 << 8
	ld		hl, BtnBar
	call	PrintStrClr


	ld		hl, VerMsg1
	ld		de, LST_FIRST_LINE << 8
	call	PrintStr
	ld		hl, VerMsg2
	ld		de, LST_FIRST_LINE + 1 << 8
	call	PrintStr	
	ld		hl, VerMsg3
	ld		de, LST_FIRST_LINE + 2 << 8
	call	PrintStr


	ld		a, SCR_LBL_CLR
	ld		hl, MsgDskInf
	ld		de, LST_DISK_INFO << 8
	call	PrintStrClr

	ld		a, SCR_LBL_CLR
	ld		hl, MsgFileInf
	ld		de, LST_FILE_INFO << 8
	call	PrintStrClr

	ld		a, SCR_LBL_CLR
	ld		hl, MsgMessages
	ld		de, LST_LINE_MSG << 8
	call	PrintStrClr

	ld		de, (LST_FIRST_LINE << 8) | LST_FIRST_COL + 1
	ld		(LineCol), de
	ld		hl, AUCnt
	ld		de, 0
	ld		(hl), de

	ld		a, SCR_SEL_CLR
	call	DrawCursor

	call	SetFastKeys

	ret


DisplayDiskInfo:
	ld		a, (RWTSDrive)
	add		'A' + $80
	ld		(MsgDriveLet), a
	ld		hl, MsgDrive
	ld		de, LST_DISK_INFO + 1 << 8
	call	PrintStr

	ld		a, (FileCnt)
	ld		l, a
	ld		h, 0
	ld		de, MsgFilesCntNo
	call	Byte2Txt
	ld		hl, MsgFilesCnt
	ld		de, LST_DISK_INFO + 2 << 8
	call	PrintStr

	ld		de, (AUCnt)
	ld		hl, MAX_FREE_AU_CNT
	or		a
	sbc		hl, de
	rl		l								;*2, 2K/AU
	rl		h
	ld		de, MsgFreeSpaceNo - 2
	call	Word2Txt
	ld		a, ':'
	ld		(MsgFreeSpaceNo -1), a
	ld		hl, MsgFreeSpace
	ld		de, LST_DISK_INFO + 3 << 8
	call	PrintStr

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcFileCache:
	ld		a, (SelFile)
	ld		de, CACHE_SZ
	call	Mul
	ld		bc, FileCache
	add		hl, bc					;HL = file AU cnt
	ld		(SelFileCache), hl
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ReadKeyLoop:
	call	CalcFileCache
	call	DisplayFileInfo

	call	ReadChar
	ld		(LastKey), a

	cp		KEY_DOWN
	jr		nz, CheckUp

	ld		a, (FileCnt)
	ld		b, a
	ld		a, (SelFile)
	inc		a
	cp		b
	jr		nc, ReadKeyLoop
	ld		(SelFile), a
	jp		MoveIt

CheckUp:
	cp		KEY_UP
	jr		nz, CheckRight

	ld		a, (SelFile)
	or		a
	jr		z, ReadKeyLoop

	dec		a
	ld		(SelFile), a
	jp		MoveIt

CheckRight:
	cp		KEY_RIGHT
	jr		nz, CheckLeft

	ld		a, (FileCnt)
	ld		b, a
	ld		a, (SelFile)
	add		LST_LINES_CNT
	cp		b
	jr		nc, ReadKeyLoop

	ld		(SelFile), a
	jp		MoveIt

CheckLeft:
	cp		KEY_LEFT
	jr		nz, CheckEnter

	ld		a, (SelFile)
	sub		LST_LINES_CNT
	jr		c, ReadKeyLoop

	ld		(SelFile), a
	jp		MoveIt

CheckEnter:
	cp		KEY_ENTER
	jp		nz, CheckKeyInfo
	call	HandleFile
	jp		HCRunMain

CheckKeyInfo:
	cp		'4'
	jr		nz, CheckKeyCopy
	ld		ix, (SelFileCache)
	ld		hl, MsgReadingExt
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadFileHeader
	ld		hl, MsgClear
	ld		de, LST_LINE_MSG+1 << 8
	ld		a, SCR_DEF_CLR
	call	PrintStrClr
	jp		ReadKeyLoop
	
CheckKeyCopy:
	cp		'5'
	jr		nz, CheckKeyFileInfo
	
	ld 		a, (RWTSDrive)
	inc		a
	xor		%11
	add		'A'-1
	ld		(MsgCopyFileDrv), a
	ld		hl, MsgCopyFile
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	ld	hl, (SelFileCache)
	call	CopyFile
	or		a
	jr		z, CopyFileOK
	
	ld		l, a
	ld		h, 0
	ld		de, MsgErrCode
	call	Byte2Txt
	ld		hl, MsgErr
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar
	
CopyFileOK:
	jp		HCRunInitDisk

CheckKeyFileInfo:
	cp		' '
	jr		nz, CheckKeyDriveA
	call	ReadAllHeaders
	jp		ReadKeyLoop

CheckKeyDriveA:
	cp		'1'
	jr		nz, CheckKeyDriveB
	ld		a, DRIVE_A_CPM
	jp		SelectDrive
	
CheckKeyDriveB:
	cp		'2'
	jr		nz, CheckKeyView
	ld		a, DRIVE_B_CPM
	jp		SelectDrive
	
CheckKeyView:
	cp		'3'
	jr		nz, CheckKeyRename
	call	ViewFile
	jp		HCRunMain
	
CheckKeyRename:
	cp		'6'
	jr		nz, CheckKeyDel
	
	ld		hl, MsgNewFileName
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	
	ld		hl, MsgClear
	ld		de, DataBuf
	ld		bc, NAMELEN
	ldir
	ld		a, $80 | ' '
	ld		(de), a
	ld		de, LST_LINE_MSG + 2 << 8
	ld		hl, DataBuf
	call	PrintStr
	
	ld		de, LST_LINE_MSG + 2 << 8
	ld		bc, NAMELEN
	call	ReadString
	
	ld		de, DataBuf
	ld		a, (de)
	cp		' '					;If starting with space, input was canceled.
	jp		z, RenameCanceled
	ld		hl, (SelFileCache)
	call	RenameFile
	jp		HCRunInitDisk
	
RenameCanceled:
	ld		hl, MsgClear
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR
	call	PrintStrClr
	jp		ReadKeyLoop
	
CheckKeyDel:
	cp		'8'
	jr		nz, CheckKeyAttrib
	
	ld		hl, MsgDelete
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar
	cp		'y'
	jr		z, DoFileDelete
	ld		hl, MsgClear
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR
	call	PrintStrClr
	jp		ReadKeyLoop
DoFileDelete:	
	ld		hl, (SelFileCache)
	ld 		a, (RWTSDrive)
	inc		a					;Convert to BASIC drive number: 1,2
	call	DeleteFile
	jp		HCRunInitDisk
	
CheckKeyAttrib:
	cp		'7'
	jr		nz, CheckKeyExtra
	
	ld		hl, MsgSetRO
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar
	ld		e, 0
	cp		'y'	
	jr		nz, CheckSYS
	ld		e, 1

CheckSYS:	
	push	de
	ld		hl, MsgSetSYS
	ld		de, LST_LINE_MSG + 2 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar
	cp		'y'
	pop		de
	jr		nz, AttrChange
	ld		a, %10
	or		e
	ld		e, a
	
AttrChange:		
	ld		hl, (SelFileCache)
	call	ChangeFileAttrib
	jp		HCRunInitDisk	
	
SelectDrive:
	ld 		(RWTSDrive), a
	jp		HCRunInitDisk
	
CheckKeyExtra:
	cp		'9'
	jp		nz, CheckKeyExit
	ld		hl, MsgMenu0
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	ld		a, (RWTSDrive)
	add		'A'
	ld		(MsgMenu1Drv), a
	ld		(MsgFormatDrv), a
	
CheckKeyExtraMenu:
	ld		hl, MsgMenu1
	ld		de, LST_LINE_MSG + 2 << 8
	call	PrintStr
	ld		hl, MsgMenu2
	ld		de, LST_LINE_MSG + 3 << 8
	call	PrintStr
	ld		hl, MsgMenu3
	ld		de, LST_LINE_MSG + 4 << 8
	call	PrintStr
	call	ReadChar
	push	af
	
		ld		hl, MsgClear
		ld		de, LST_LINE_MSG + 2 << 8
		call	PrintStr
		ld		hl, MsgClear
		ld		de, LST_LINE_MSG + 3 << 8
		call	PrintStr
		ld		hl, MsgClear
		ld		de, LST_LINE_MSG + 4 << 8
		call	PrintStr
	
	pop		af
	cp		'3'
	jr		z, ExtraMenuExit
	
	cp		'1'
	jr		nz, CheckExtra2
	
	ld		hl, MsgFormat
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	
	call	FormatDisk
	or		a
	jr		z, FormatDiskOK

	;Display error for format
	ld		l, a
	ld		h, 0
	ld		de, MsgErrCode
	call	Byte2Txt
	ld		hl, MsgErr
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	call	ReadChar
	
FormatDiskOK:	
	jr		ExtraMenuExit
	
CheckExtra2:	
	cp		'2'
	jr		nz, CheckKeyExtraMenu
	
	call	CopyDisk	
	jr		ExtraMenuExit
	
ExtraMenuExit:
	jp		HCRunMain

CheckKeyExit:
	cp		'0'
	jp		nz, ReadKeyLoop
	jp		HCRunEnd

MoveIt:
	call 	MoveCursor
	jp		ReadKeyLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


DisplayFilename:
	LD		B, NAMELEN
DispLoop:
	LD		A, (DE)

	;clear bit 7
	RES 	7, A
	LD		(CODE), A

	INC		DE
	PUSH	DE
	PUSH	BC
		CALL	PrintChar
	POP		BC
	POP 	DE

	LD		HL, COL
	INC		(HL)
	DJNZ	DispLoop
	;now a name is displayed

	;check bounds
	LD		A, (LINE)
	INC		A
	CP		LST_LINES_CNT + LST_FIRST_LINE
	JR		C, LineOK

	;set names column to the next one
	LD		A, (NameCol)
	ADD		NAMELEN + 1
	LD		(NameCol), A

	LD		A, LST_FIRST_LINE
LineOK:
	LD		(LINE), A

	LD		A, (NameCol)
	LD		(COL), A

	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisplayFilenames:
	ld		de, FileCache
	ld		a, (FileCnt)
	ld		b,	a

DisplayFilenamesLoop:
	push	bc
		push	de
			call	DisplayFilename
		pop		de
		ex		de, hl
		ld		bc, CACHE_SZ
		add		hl, bc
		ex		de, hl
	pop		bc
	djnz	DisplayFilenamesLoop

	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Selects only valid filenames (not deleted and only from first extension)
GetFileNames:
	ld ix, TrackBuf
	ld de, FileCache
	ld b, MAX_EXT_CNT

StoreFilenamesLoop:
	xor a
	cp (ix + EXT_DEL_FLAG)
	jp nz, NextExt			;check for deleted

	;count AU
	exx
	push hl
		call CheckExtAlloc
		ex de, hl			;save first AU no.

		;store disk alocated AU count
		ld hl, (AUCnt)
		ld c, b
		ld b, 0
		add hl, bc
		ld (AUCnt), hl
	pop hl
	exx

	xor	a
	cp (ix + EXT_IDX)		;check if first extension
	jr nz, FindExt

	push ix
	pop hl
	inc hl					;skip del flag

	push bc
		push de
			push hl
				ex de, hl
				call DisplayFilename
			pop hl
		pop de
		ld bc, NAMELEN
		ldir				;save file name

		exx
		push 	de			;de = first AU
		exx
		pop		hl
		ex		de, hl
		ld		(hl), de	;save first AU

		inc		hl
		inc		hl

		exx					;save AU cnt for file
		push	bc
		exx
		pop		bc
		ld		(hl), bc

		inc		hl
		inc		hl

		;xor		a			;make flag 0 to signal that header is not read yet
		;ld		(hl), a

		ld		bc, HDR_SZ + 1
		add		hl, bc

		ex		de, hl
	pop bc


	ld 		a, (FileCnt)			;inc file counter
	inc		a
	ld 		(FileCnt), a
	cp		LST_MAX_FILES
	jr		c, NextExt
	jr		GetFileNamesEnd


FindExt:					;BC' = AU cnt for this ext
	push	bc
		push 	de
			push	ix
			pop		de
			inc		de				;DE = name to find

			ld		hl, FileCache
			ld		a, (FileCnt)
			ld		c, a
			call	FindCache
			jr		nz, FindExtEnd

			ld		bc, CACHE_AU_CNT
			add		hl, bc
			exx
			push	bc
			exx
			pop		bc

			ld		de, (hl)		;DE = Current AU CNT for file
			ex		de, hl
			add		hl, bc
			ex		de, hl
			ld		(hl), de
FindExtEnd:
		pop		de
	pop		bc

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
	ld		ix, (SelFileCache)
	push	ix
		ld		a, (ix + CACHE_FLAG)
		or		a
		call	z, ReadFileHeader

		ld		a, (ix + CACHE_HDR + HDR_TYPE)
		cp		PROG_TYPE
		jr		z, HandleFileProg

		cp		BYTE_TYPE
		jr		nz, HandleFileText

		ld		hl, (ix + CACHE_HDR + HDR_LEN)		;get length
		ld		de, -SCR_LEN			;check if the length is for a screen$ file
		add		hl, de
		ld		a, h
		or		l
		jr		z, HandleFileSCR


HandleFileCODE:
		ld		hl, MsgLoadingCODE
		ld		de, LST_LINE_MSG+1 << 8
		ld		a, SCR_DEF_CLR | CLR_FLASH
		call	PrintStrClr

		;Copy file load function to printer buffer to not be overwritten by CODE block.
		ld		hl, FileLoad
		ld		de, PRN_BUF
		ld		bc, FileLoadEnd - FileLoad
		ldir
		ld		a, $C9
		ld		(de), a				;put a RET here, since FileFree won't be called.

	pop		hl
	ld		de, (DataBuf + HDR_ADDR)	;get CODE start address to load to and then execute
	pop		bc						;balance stack to exit to BASIC after CODE returns - 1 call for this function
	pop		bc						;2nd, 3rd call for error handler
	pop		bc
	ld		(ERRSP), bc
	push	de						;push CODE address to return to = start of CODE block
	jp		PRN_BUF




HandleFileSCR:
		ld		hl, MsgLoadingSCR
		ld		de, LST_LINE_MSG+1 << 8
		ld		a, SCR_DEF_CLR | CLR_FLASH
		call	PrintStrClr

	pop		hl
	
	ifdef _ROM_FNT_
	;Load to alternate SCREEN$ memory
	ld		de, HC_VID_BANK1
	call	FileLoad
	;Set display to alternate SCREEN$ memory
	ld		a, HC_CFG_VID_C000
	out 	(HC_CFG_PORT), a
	call	ReadChar
	;Set back to regular SCREEN$ memory
	ld		a, HC_CFG_VID_4000
	out 	(HC_CFG_PORT), a
	else
	ld		de, 16384
	call	FileLoad
	call	ReadChar
	endif
	
	ret

HandleFileProg:
		ld		hl, MsgLoadingPrg
		ld		de, LST_LINE_MSG+1 << 8
		ld		a, SCR_DEF_CLR | CLR_FLASH
		call	PrintStrClr
	pop		hl
	call	LoadProgram
	ret


HandleFileText:
	pop		hl
	call	ViewFile
	ret


ViewFile:
	call	ClrScr
	ld		hl, (SelFileCache)
	ld		de, DataBuf + 2048
	
	push	de
		push	de
			call	FileLoad		;DE = last addr.
			ex		de, hl
		pop		de
		or		a
		sbc		hl, de
		ld		b, h
		ld		c, l
	pop		hl
	call	InitViewer
	call	PrintLoop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


DisplayFileInfo:
	ld		hl, (SelFileCache)
	push	hl
		;disk size
		ld		bc, CACHE_AU_CNT
		add		hl, bc
		ld		de, (hl)
		ex		de, hl
		ld		de, MsgFileSzDskN

		ld		b, 11
MultKb:
		add		hl, hl
		djnz	MultKb


		call	Word2Txt
		ld		hl, MsgFileSzDsk
		ld		de, LST_FILE_INFO + 1 << 8
		call	PrintStr
	pop		hl
	push	hl
		;attributes
		ld		bc, CACHE_NAME + RO_POS
		add		hl, bc
		ex		de, hl
		ld		hl, MsgFileAttrN
		ld		a, (de)
		and		%10000000
		jr		z, NotRO

		ld		bc, '/R'
		ld		(hl), bc
		inc		hl
		inc		hl
		ld		bc, ',O'
		ld		(hl), bc
		inc		hl
		inc		hl
		jr		CheckSys
NotRO:
		ld		bc, '--'
		ld		(hl), bc
		inc		hl
		inc		hl
		ld		bc, ',-'
		ld		(hl), bc
		inc		hl
		inc		hl

CheckSys:
		inc		de
		ld		a, (de)
		and		%10000000
		jr		z, NotSYS

		ld		bc, 'IH'
		ld		(hl), bc
		inc		hl
		inc		hl
		ld		a, 'D' + $80
		ld		(hl), a
		jr		AttrEnd
NotSYS:
		ld		bc, '--'
		ld		(hl), bc
		inc		hl
		inc		hl
		ld		a, '-' + $80
		ld		(hl), a
AttrEnd:
		ld		de, LST_FILE_INFO + 2 << 8
		ld		hl, MsgFileAttr
		call	PrintStr
	pop		ix
	push	ix
		ld		a, (ix + CACHE_FLAG)
		or		a
		jp		z, HeadNotRead

		ld		a, (ix + CACHE_FIRST_AU)
		or		(ix + CACHE_FIRST_AU + 1)
		jp		z, HeadNotRead

		ld		a, (ix + CACHE_HDR)
		cp		PROG_TYPE
		jr		nz, CheckNoArr

		ld		hl, MsgFileTypePrg
		ld		de, MsgFileTypeN
		call	MoveMsg
		jr		PrepFileLen

CheckNoArr:
		cp		NUMB_TYPE
		jr		nz, CheckChrArr

		ld		hl, MsgFileTypeNoA
		ld		de, MsgFileTypeN
		call	MoveMsg
		jr		PrepFileLen

CheckChrArr:
		cp		CHAR_TYPE
		jr		nz, CheckByte

		ld		hl, MsgFileTypeChrA
		ld		de, MsgFileTypeN
		call	MoveMsg
		jr		PrepFileLen

CheckByte:
		cp		BYTE_TYPE
		jr		nz, CheckText

		ld		hl, (ix + CACHE_HDR + HDR_LEN)
		ld		bc, -SCR_LEN
		add		hl, bc
		ld		a, h
		or		l
		jr		nz, NotScr

		ld		hl, MsgFileTypeSCR
		ld		de, MsgFileTypeN
		call	MoveMsg
		jr		PrepFileLen
NotScr:
		ld		hl, MsgFileTypeByt
		ld		de, MsgFileTypeN
		call	MoveMsg
		jr		PrepFileLen

CheckText:
		ld		hl, MsgFileTypeText
		ld		de, MsgFileTypeN
		call	MoveMsg
		jr		NoHeader

PrepFileLen:
		;File len
		ld		l, (ix + CACHE_HDR + HDR_LEN)
		ld		h, (ix + CACHE_HDR + HDR_LEN + 1)
		ld		de, MsgFileLenN
		call	Word2Txt
		ld		h, 'B' | $80
		ld		l, ' '
		ld		(MsgFileLenN + 5), hl

		ld		a, (ix + CACHE_HDR + HDR_TYPE)
		cp		PROG_TYPE
		jr		z, PrintProgStart

		cp		BYTE_TYPE
		jr		z, PrintByteStart
		jr		PrintStartNotRead

PrintProgStart:
		ld		l, (ix + CACHE_HDR + HDR_LINE)
		ld		h, (ix + CACHE_HDR + HDR_LINE + 1)
		jr		PrintStart

PrintByteStart:
		ld		l, (ix + CACHE_HDR + HDR_ADDR)
		ld		h, (ix + CACHE_HDR + HDR_ADDR + 1)
		jr		PrintStart


HeadNotRead:
		ld		hl, MsgFileTypeUnkn
		ld		de, MsgFileTypeN
		call	MoveMsg

NoHeader:
		ld		hl, MsgFileTypeUnkn
		ld		de, MsgFileLenN
		call	MoveMsg

PrintStartNotRead:
		ld		hl, MsgFileTypeUnkn
		ld		de, MsgFileStartN
		call	MoveMsg
		jr		PrintStartStr

PrintStart:
	ld		e, ' '
	ld		d, ' ' | $80
	ld		(MsgFileStartN + 5), de
	ld		de, MsgFileStartN
	call	Word2Txt
PrintStartStr:
	ld		de, LST_FILE_INFO + 4 << 8
	ld		hl, MsgFileStart
	call	PrintStr

	pop		ix
	ld		de, LST_FILE_INFO + 3 << 8
	ld		hl, MsgFileType
	call	PrintStr

	ld		de, LST_FILE_INFO + 5 << 8
	ld		hl, MsgFileLen
	call	PrintStr

	ret

MoveMsg:
	ld		bc, 7
	ldir
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadAllHeaders:
	ld		hl, MsgReadingExt
	ld		de, LST_LINE_MSG+1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr

	call	CalcFileCache

	ld		a, (SelFile)
	ld		b, a
	ld		a, (FileCnt)
	sub		b
	or		a
	ret		z

	ld		b, a

	ld		ix, (SelFileCache)
NextFile:
	push	bc
		call	ReadFileHeader
		ld		bc, CACHE_SZ
		add		ix, bc
		push	ix
			call	CalcFileCache
			call	DisplayFileInfo
		pop		ix

		call	KbdHit
		jr		c, AKey
	pop		bc
	jr		ReadAllHeadersEnd

AKey:
		ld		a, (SelFile)
		inc		a
		ld		b, a
		ld		a, (FileCnt)
		cp		b
		jr		z, DontInc
		ld		a, b
		ld		(SelFile), a
		call	MoveCursor
	pop		bc
	djnz	NextFile

ReadAllHeadersEnd:
	ld		hl, MsgClear
	ld		de, LST_LINE_MSG+1 << 8
	ld		a, SCR_DEF_CLR
	call	PrintStrClr
	ret

DontInc:
	pop		bc
	jr		ReadAllHeadersEnd
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	include "hccfg.asm"
	include "ui.asm"
	include "math.asm"
	include "disk.asm"
	include "bdos.asm"
	include "txtview.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VerMsg1			DEFM	'HC Commander 1.', '0' + $80
VerMsg2			DEFM	'george.chirtoac', 'a' + $80
VerMsg3			DEFM	'@gmail.com, 202', '3' + $80
MsgDskInf		DEFM	'Disk Info      ', ' ' + $80
MsgFileInf		DEFM	'File Info      ', ' ' + $80
MsgMessages		DEFM	'Messages       ', ' ' + $80
BtnBar			DEFM	'1-A: 2-B: 3-View 4-Prop 5-Copy 6-Ren 7-Attr 8-Del 9-Disk 0-Exi', 't' + $80
MsgDrive		DEFM	'Drive   :      '
MsgDriveLet		DEFM	'A' + $80
MsgFilesCnt		DEFM	'Files   :'
MsgFilesCntNo	DEFM	'000/12', '8' + $80
MsgFreeSpace	DEFM	'Free KB :'
MsgFreeSpaceNo	DEFM	'000/63', '6' + $80
MsgErr			DEFM	'Error code '
MsgErrCode		DEFM	'000:',' ' + $80
MsgLoadingPrg	DEFM	'Loading Progra', 'm' + $80
MsgLoadingSCR	DEFM	'Loading SCREEN', '$' + $80
;MsgLoadingTXT	DEFM	'Loading TEX', 'T' + $80
MsgLoadingCODE	DEFM	'Loading CODE (!', ')' + $80
MsgFileSzDsk	DEFM	'Disk Len:'
MsgFileSzDskN	DEFM	'00000 ', 'B' + $80
MsgFileAttr		DEFM	'Attrib  :'
MsgFileAttrN	DEFM	'R/O,HI', 'D' + $80
MsgFileType		DEFM	'FileType:'
MsgFileTypeN	DEFM	'         ', ' ' + $80
MsgFileTypePrg	DEFM	'Progra', 'm' + $80
MsgFileTypeByt	DEFM	'Bytes ', ' ' + $80
MsgFileTypeSCR	DEFM	'SCREEN', '$' + $80
MsgFileTypeChrA	DEFM	'Chr.Ar', 'r' + $80
MsgFileTypeNoA	DEFM	'No. Ar', 'r' + $80
MsgFileTypeText	DEFM	'Data  ', ' ' + $80
MsgFileTypeUnkn	DEFM	'N/A   ', ' ' + $80
MsgFileLen		DEFM	'Length  :'
MsgFileLenN		DEFM	'65535 ', 'B' + $80
MsgFileStart	DEFM	'Start   :'
MsgFileStartN	DEFM	'65535 ', ' ' + $80
MsgReadingExt	DEFM	'Reading heade', 'r' | $80
MsgClear		DEFM	'               ', ' ' | $80
MsgDelete		DEFM	'Del file (y/n)', '?' | $80
MsgSetRO		DEFM	'Set R/O (y/n)', '?' | $80
MsgSetSYS		DEFM	'Set HID (y/n)', '?' | $80
MsgNewFileName	DEFM	'Name,none=abort', ':' | $80
MsgCopyFile		DEFM	'Copying to '
MsgCopyFileDrv	DEFM	'A', ':' | $80
MsgMenu0		DEFM	'Disk options', ':' | $80
MsgMenu1		DEFM	'1.Format disk '
MsgMenu1Drv		DEFM	'A', ':' | $80
MsgMenu2		DEFM	'2.Copy dis', 'k' | $80
MsgMenu3		DEFM	'3.Exit men', 'u' | $80
MsgFormat		DEFM	'Formatting '
MsgFormatDrv	DEFM	'A', ':' | $80
MsgBlocksLeft	DEFB	'000 blocks lef', 't' | $80

	ifndef	_ROM_FNT_
FontTable:	
	incbin "cpmfnt.bin"
	endif
EndCode:

;Unalocated variables
UnallocStart	EQU		$
FileCnt			EQU		$						;File counter, 1B
NameCol			EQU		FileCnt + 1				;Column for file name, 1B
SelFile			EQU		NameCol + 1 			;Selected file using cursor, 1B
CursorAddr		EQU		SelFile + 1				;2 B
LastKey			EQU		CursorAddr + 2			;1 B
AUCnt			EQU		LastKey + 1				;2 B
SelFileCache	EQU		AUCnt + 2				;2 B


FileCache		EQU		SelFileCache + 2					;cache table, size = 128 * 25 = 3200
TrackBuf		EQU		FileCache + MAX_EXT_CNT*CACHE_SZ	;size = 16 * 256 = 4096
	ifdef	_ROM_FNT_
FontTable		EQU		TrackBuf + SPT*SECT_SZ + 100		;TBD: Font table gets partialy overwritten by TrackBuf
DataBuf			EQU		FontTable + 872
	else
DataBuf			EQU		TrackBuf + SPT*SECT_SZ
	endif

TheEnd			EQU		DataBuf
FileIdx			EQU		DataBuf
	
	savebin "hccmd.bin", Start, EndCode - Start