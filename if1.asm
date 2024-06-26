;HC IF1 routines and constants

;IF1 routines error codes, also returned by BASIC commands
;12 = Writing to a 'read' file
;13 = Reading a 'write' file
;14 = Disk 'write' protected (by hardware, disk notch open)
;15 = Disk full (disk or catalog full)
;16 = Disk error (hardware error)
;17 = File not found
;23 = Disk R/O (disk change detected, software R/O)
;24 = File R/O (attempting to delete or copy a file with R/O attribute)

;Error codes returned by the low level IF1 RWTS routine, from "ABC de calculatoare personale..." book.
;00h = OK
;08h = cannot format disk
;10h = disk protected (read-only?)
;20h = volume error
;40h = drive error
;80h = reading error
;Codes I encountered:
;04h = a CP/M disk was inserted instead of a BASIC one


	ifndef	_DISK_
	define	_DISK_

	include	"math.asm"

DRIVE_CUR_BAS	EQU	0
DRIVE_A_BAS	EQU	1
DRIVE_B_BAS	EQU	2
DRIVE_A_CPM	EQU	0
DRIVE_B_CPM	EQU	1
;Disk geometry stuff
SPT		EQU	16	;sectors per track
SECT_SZ		EQU	256	;sector size in bytes
TRACK_CNT	EQU	80	;track count
HEAD_CNT	EQU	2	;disk face count
AU_SZ		EQU	2048	;allocation unit size in bytes (8 sectors, half of a track)
EXT_SZ		EQU	32	;directory entry size
DIR_TRK_CNT	EQU	1	;tracks rezerved for directory
EXT_AU_CNT	EQU	8	;allocation units in one extension
SPAL		EQU	(AU_SZ/SECT_SZ);sectors per allocation unit
MAX_EXT_CNT	EQU	(SPT * DIR_TRK_CNT * SECT_SZ / EXT_SZ);maximum directory entries
MAX_FREE_AU_CNT	EQU	((TRACK_CNT * HEAD_CNT - DIR_TRK_CNT) * SPT * SECT_SZ)/AU_SZ ;max free allocation units (318)
REC_SZ		EQU	128	;cp/m record size
DEL_MARKER	EQU	$E5


;Extension structure (directory entry)
EXT_DEL_FLAG	EQU	0
EXT_NAME	EQU	1
EXT_IDX		EQU	12
EXT_S1		EQU	13
EXT_S2		EQU	14
EXT_RC		EQU	15
EXT_AU0		EQU	16
EXT_AU1		EQU	18
EXT_AU2		EQU	20
EXT_AU3		EQU	22
EXT_AU4		EQU	24
EXT_AU5		EQU	26
EXT_AU6		EQU	28
EXT_AU7		EQU	30
EXT_SIZE	EQU	32

;FCB structure
FCB_DRIVE	EQU 0
FCB_NAME	EQU EXT_NAME
FCB_EX_IDX	EQU EXT_IDX
FCB_S1		EQU EXT_S1
FCB_S2		EQU EXT_S2
FCB_RC		EQU EXT_RC
FCB_AU		EQU EXT_AU0
FCB_CR		EQU 32
FCB_R0		EQU 33
FCB_R1		EQU 34
FCB_R2		EQU 35
FCB_SIZE	EQU 36



;System variables for disk
DSTR1		EQU	$5CD6	;drive
FSTR1		EQU	$5CDC	;file name
NSTR1		EQU	$5CDA	;name length
HD11		EQU	$5CED	;BDOS argument
COPIES		EQU	$5CEF	;BDOS function

ERRSP		EQU	$5C3D
ERRNR		EQU	$5C3A
ERRMSG		EQU	$0260

PROG		EQU	$5C53
VARS		EQU	$5C4B
STKEND		EQU	$5C65

PRN_BUF		EQU	23296

REPDEL		EQU	23561
REPPER		EQU	23562
PIP		EQU	23609
LAST_K		EQU	$5C08

TAPE_LOAD		EQU	$0562		;Originally $0556, but we want return to our code, not ROM error routine.
TAPE_SAVE		EQU	$04C2
TAPE_HDR_LEN		EQU	17
TAPE_HDR_NAME_LEN	EQU	10
TAPE_BLOCK_ID_HDR	EQU	0
TAPE_BLOCK_ID_BLK	EQU	$FF

TAPE_HDR_TYPE		EQU	0
TAPE_HDR_NAME		EQU	1
TAPE_HDR_BLOCK_LEN	EQU	11
TAPE_HDR_BLOCK_START	EQU	13
TAPE_HDR_VARS		EQU	15


;RWTS routine commands
RWTS_CMD_SEEK	EQU	0	;position head
RWTS_CMD_READ	EQU	1	;read sector
RWTS_CMD_WRITE	EQU	2	;write sector
RWTS_CMD_FMT	EQU	4	;format all tracks


;File name stuff
NAMELEN			EQU	11	;name length
RO_POS			EQU	8	;read-only attribute position in name
SYS_POS			EQU	9	;system attribute position in name

;File types (first byte in header)
PROG_TYPE		EQU	0	;program
NUMB_TYPE		EQU	1	;number array
CHAR_TYPE		EQU	2	;char array
BYTE_TYPE		EQU	3	;bytes
TEXT_TYPE		EQU	4	;text, >= 4

;File header offsets
HDR_TYPE	EQU	0
HDR_LEN		EQU	1
HDR_ADDR	EQU	3
HDR_PLEN	EQU	5
HDR_LINE	EQU	7
HDR_SZ		EQU	9

;BASIC disk channel structure
CH_RW_FLAG	EQU 11
CH_FCB	EQU	12
CH_DATA	EQU	50
CH_DMA	EQU CH_DATA - CH_FCB	;offset of DMA from start of FCB

CACHE_NAME		EQU	0			;11B
CACHE_FIRST_AU	EQU	NAMELEN		;2B
CACHE_AU_CNT	EQU	CACHE_FIRST_AU + 2	;2B
CACHE_FLAG	EQU	CACHE_AU_CNT + 2	;1B
CACHE_HDR	EQU	CACHE_FLAG + 1	;9B
CACHE_SZ	EQU	25			;11 + 2 + 2 + 1 + 9
CACHE_FLAG_HDR_READ	EQU	1
CACHE_FLAG_TAGGED	EQU	2

LOAD_ADDR	EQU	2625	;address of the load procedure in IF1 ROM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF1Init:
	rst	08
	defb	49	;create system variables
	ret

;ReadWriteTrackSector
;A=command: 0, 1, 2, 4
RWTS:
	ld (RWTSCmd), a
	ld hl, RWTSParams
	ld (HD11), hl
	rst 08
	DEFB 58
	ret


;D = sector, E = track
;HL = dma
ReadOneDiskSector:
	ld	(RWTSDMA), hl
	ld	(RWTSTrack), de
	;ld (RWTSDrive), a
	ld	a, RWTS_CMD_READ
	jr	RWTS
	
;D = sector, E = track
;HL = dma
WriteOneDiskSector:
	ld	 (RWTSDMA), hl
	ld	 (RWTSTrack), de
	;ld (RWTSDrive), a
	ld	a, RWTS_CMD_WRITE
	jr	RWTS	
	
FormatDisk:
	ld	hl, DataBuf
	ld	(hl), DEL_MARKER
	ld 	(RWTSDMA), hl
	ld 	a, RWTS_CMD_FMT
	call	RWTS
	ld	a, (RWTSRes)
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Allocation unit no. to track/sector
;Formula: T=(AllocUnit*SPAL)/SPT; Sect=T mod SPT; Track=T/2 (2 disk faces); Head=T mod 2
;IN:  HL=alloc. unit no.
;OUT: B=sector; C=track (head is determined by the sector number)
AU2TS:
	ld c, SPT/SPAL
	call Div			;A = sector
	push af		
		xor a
		rr h
		rr l
		rr a

		ld c, l
		ld b, 0
		or a
		jr z, Track0
		ld b, SPT
Track0:
	pop af
	or a
	jr z, FirstAU
	ld a, SPAL
FirstAU:
	add a, b
	ld  b, a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Checks the allocation units number used in extension
;IN:	IX = extension addr
;OUT:	B = no. of allocation units used
;	C = no. of records used in ext.
;	HL = first alloc. unit no.
;	DE = last alloc. unit no.
CheckExtAlloc:
	push ix
		ld bc, EXT_RC
		add ix, bc
		ld c, (ix)	;save rec. no.
		inc ix
		ld l, (ix)
		ld h, (ix + 1)
		ld b, EXT_AU_CNT
CheckAU:
		ld a, (ix)
		or (ix + 1)
		jr z, CheckAUEnd
		ld e, (ix)
		ld d, (ix + 1)
		inc ix
		inc ix
		djnz CheckAU
CheckAUEnd:
		ld a, EXT_AU_CNT
		sub b
		ld b, a
	pop ix
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Input: TrackBuffer
;Output: DataBuf = used block count (2 bytes), used block numbers (2 bytes each), 640 + 2 bytes
ReadUsedBlocksList:
	ld	ix, TrackBuf	;source buffer
	ld	hl, UsedBlockListCnt 	;destination buffer
	ld	bc, (AUCntMaxFree)	;loop counter
	ld	de, 2			;counter of used blocks, start with 2
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	
	;Add blocks 0 and 1 for directory
	ld	de, 0
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	
	inc	de
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	
ReadUsedBlocksLoop:	
	xor	a
	cp	(ix)
	jr	nz, ReadUsedBlocksSkip2;skip dir entry because it's not for user code 0
	
	push	ix
	push	bc
		ld	b, EXT_AU_CNT
		ld	de, EXT_AU0
		add	ix, de
		
ReadUsedBlocksLoop2:		
		ld	e, (ix)
		ld	d, (ix+1)
		ld	a, e
		or	d
		jr	z, ReadUsedBlocksSkip;end dir entry reading when the AU number is 0
		
		ld	(hl), e
		inc	hl
		ld	(hl), d
		inc	hl
		
		inc	ix
		inc	ix
		
		ld	de, (UsedBlockListCnt)
		inc	de
		ld	(UsedBlockListCnt), de
		
		djnz	ReadUsedBlocksLoop2
		
	
ReadUsedBlocksSkip:	
	pop	bc
	pop	ix
ReadUsedBlocksSkip2:	
	ld	de, EXT_SZ
	add	ix, de

	dec	bc
	ld	a, b
	or	c
	jr	nz, ReadUsedBlocksLoop
	
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Reads 8 sectors for an AU
;HL = block number, DE = destination buffer
ReadFSBlock:
	push	de
		call	AU2TS	;B=sector, C=track
	pop		hl		;HL=dest
	
	ld	d, b
	ld	e, c	
	ld	b, SPAL

	call	ReadDiskSectors	
	ret


;Write 8 sectors for an AU
;HL = block number, DE = source buffer
WriteFSBlock:
	push	de
		call	AU2TS	;B=sector, C=track
	pop	hl		;HL=dest
	
	ld	d, b
	ld	e, c	
	ld	b, SPAL

	call	WriteDiskSectors
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Copies the allocated blocks from one disk to another, dual drive.
;TODO: Sort blocks to minimize seek time and improve copy speed.
CopyDisk:
	;Get list of used blocks in current disk, max 632 bytes
	call	ReadUsedBlocksList
	ld	ix, UsedBlockListBlk	
	
CopyDiskLoop:	
	ld	hl, (UsedBlockListCnt)	;block count, max 320, 2 for catalog
	ld	de, MsgBlocksLeft
	call	Byte2Txt
	ld	hl, MsgBlocksLeft
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_ASK_CLR
	call	PrintStrClr	
	
	;Calculate how many blocks to read = min(MAX_AU_RAM, blocks left)
	ld	hl, MAX_AU_RAM
	ld	bc, (UsedBlockListCnt)
	or	a
	sbc	hl, bc
	jr	nc, CopyDiskLoopRead		
	ld	bc, MAX_AU_RAM

CopyDiskLoopRead:		
	ld	b, c
	ld	de, CopyDiskBuf
	;save initial counter and initial block number array position
	push	bc	
	push	ix		
	
CopyDiskLoopReadLoop:		
		ld	l, (ix)
		ld	h, (ix+1)
		inc	ix
		inc	ix
		
		push	de
		push	bc		
			call	ReadFSBlock	;Stop on error or continue?
		pop	bc
		pop	de
		
		;+2048
		ld	a, d
		add	8
		ld	d, a
			
		djnz	CopyDiskLoopReadLoop
			
		;Check if selection is 1=single drive or 2=dual drive
		ld	a, (CopySelOption)
		cp	'1'
		jr	nz, CopyDiskDualDrive1
		
		;Prompt for disk change
		call	PromptDiskChangeDst
		ld	a, (RWTSDrive)		
		call	BDOSInit
		jr	CopyDiskReadEnd
		
CopyDiskDualDrive1:
		;alternate drive
		ld	a, (RWTSDrive)
		inc 	a
		xor	%11
		dec	a
		ld	(RWTSDrive), a

CopyDiskReadEnd:
	;restore initial counter and initial block number array position
	pop	ix
	pop	bc
	ld	de, CopyDiskBuf
	push	bc
	
CopyDiskLoopWriteLoop:
		ld	l, (ix)
		ld	h, (ix+1)
		inc	ix
		inc	ix
		
		push	de
		push	bc
		call	WriteFSBlock	;Stop on error or continue?
		pop	bc
		pop	de	
		
		;+2048
		ld	a, d
		add	8
		ld	d, a
		
		djnz	CopyDiskLoopWriteLoop		

CopyDiskWriteEnd:
	pop	bc
	ld	c, b
	ld	b, 0
	
	;Decrease number of blocks read by now.
	ld	hl, (UsedBlockListCnt)
	or	a
	sbc	hl, bc
	ld	(UsedBlockListCnt), hl
		
	ld	a, l
	or	h
	jr	z, CopyDiskEnd				;Exit if finished all blocks.
	
	;Check if selection is 1=single drive or 2=dual drive
	ld	a, (CopySelOption)
	cp	'1'
	jr	nz, CopyDiskDualDrive2		
	
	;Prompt for disk change
	call	PromptDiskChangeSrc
	ld	a, (RWTSDrive)		
	call	BDOSInit
	jp	CopyDiskLoop
		
CopyDiskDualDrive2:		
	;alternate drive again
	ld	a, (RWTSDrive)
	inc	a
	xor	%11
	dec	a
	ld	(RWTSDrive), a
	jp	CopyDiskLoop	
	
CopyDiskEnd:
	ld	b, 1
	call	ClearNMsgLines
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Copies the current disk blocks to COM port.	
;Send count of blocks - 2B, then for each block send block index - 2B, block buffer - 2048B.
CopyDiskToCOM:
	;Get list of used blocks in current disk, max 632 bytes
	call	ReadUsedBlocksList	
	
	;Send block count and block indexes
	ld	hl, (UsedBlockListCnt)
	add	hl, hl
	inc	hl
	inc	hl
	ld	b, h
	ld	c, l
	ld	hl, UsedBlockListCnt
	call	SERTB		
	
	ld	ix, UsedBlockListBlk		
	
CopyDiskToCOMLoop:		
	;Print block count left
	ld	hl, (UsedBlockListCnt)	;block count, max 320, 2 for catalog
	ld	de, MsgBlocksLeft
	call	Byte2Txt
	ld	hl, MsgBlocksLeft
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_ASK_CLR
	call	PrintStrClr			
	
	;Read block into buffer
	ld	l, (ix)
	ld	h, (ix+1)
	ld	de, CopyDiskBuf
	push	ix
		call	ReadFSBlock		
	pop	ix
	inc	ix
	inc	ix	
	
	;Send block buffer
	ld	hl, CopyDiskBuf
	ld	bc, AU_SZ
	call	SERTB
	
	ld	bc, (UsedBlockListCnt)
	dec	bc
	ld	(UsedBlockListCnt), bc
	
	push	ix
		call	KbdHit
	pop	ix
	ret	c
	
	ld	a, b
	or	c
	jr	nz, CopyDiskToCOMLoop
	
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
CopyDiskFromCOM:
	;Receive block count.
	ld	hl, UsedBlockListCnt
	ld	bc, 2
	ld	e, 0
	call	SERRB

	;Receive block indexes.
	ld	hl, (UsedBlockListCnt)
	add	hl, hl	
	ld	b, h
	ld	c, l
	ld	hl, UsedBlockListBlk
	ld	e, 0
	call	SERRB
	
	;Read each block by index and write to disk
	ld	ix, UsedBlockListBlk

CopyDiskFromCOMLoop:
	;Print block count left
	ld	hl, (UsedBlockListCnt)	;block count, max 320, 2 for catalog
	ld	de, MsgBlocksLeft
	call	Byte2Txt
	ld	hl, MsgBlocksLeft
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_ASK_CLR
	call	PrintStrClr			
	
	;Read block buffer
	ld	hl, CopyDiskBuf
	ld	bc, AU_SZ
	ld	e, 0
	call	SERRB
	
	;Write block to disk
	ld	l, (ix)
	ld	h, (ix+1)
	ld	de, CopyDiskBuf
	push	ix
		call	WriteFSBlock			;Stop on error or continue?		
	pop	ix
	inc	ix
	inc	ix
			
	ld	bc, (UsedBlockListCnt)
	dec	bc
	ld	(UsedBlockListCnt), bc
	
	push	ix
		call	KbdHit
	pop	ix
	ret	c
	
	ld	a, b
	or	c
	jr	nz, CopyDiskFromCOMLoop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Compare string at HL with the one at DE, max length B
;IN: HL, DE = addr. of strings to compare, B = max. length of strings to compare
;OUT: z flag, set = match, reset = mismatch
StrCmp:
	push hl
	push de
Compare:
		ld a, (de)
		cp (hl)
		jr nz, MisMatch
		inc hl
		inc de
		djnz Compare
MisMatch:
	pop de
	pop hl
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Read a file into a buffer, sector by sector.
;It's relocatable, to moved and be used when loading a CODE block.
;It's not using BDOS, but using similar calls provided by IF1.
;In: HL = Name address, DE = buffer, A = drive
IF1FileLoad:
	push	de
		ld	(FSTR1), hl
		ld	h, 0		
		ld	l, a
		ld	(DSTR1), hl
		ld	l,NAMELEN
		ld	(NSTR1), hl
		rst	08
		DEFB	51	;open disk channel

		rst	8		
		defb	53	;read sector
	pop	de
	jr	nc, FileFree

	ld	a, (ix + CH_DATA)
	cp	TEXT_TYPE
	jr	nc, FileLoadNoHeader

FileLoadHeader:
	push	ix
	pop	hl
	ld	bc, CH_DATA + HDR_SZ
	add	hl, bc
	ld	bc, SECT_SZ - HDR_SZ
	ldir

FileReadLoop:
	push	de
		rst	8		
		defb	53	;read sector
	pop	de
	jr	nc, FileFree

FileLoadNoHeader:
	push	ix
	pop	hl
	ld	bc, CH_DATA
	add	hl, bc
	ld	bc, SECT_SZ
	ldir
	jr	FileReadLoop

FileFree:
	push	de
	rst	8
	defb	56	;close channel (52) or detroy channel (56)
	pop	de
	ret
IF1FileLoadEnd:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;In: A=drive, HL = Name address, DE = buffer, B = number of sectors to save
IF1FileSave:
	push	de
	push	bc
		ld	(FSTR1), hl
		ld	h, 0
		ld	l, a
		ld	(DSTR1), hl
		ld	l,NAMELEN
		ld	(NSTR1), hl
		rst	08
		DEFB 51	;open disk channel
	pop	bc
	pop	de
	
IF1FileSaveLoop:
	push	bc
	push	de
		;Copy sector data in channel buffer.
		push	ix
		pop	hl
		ld	bc, CH_DATA
		add	hl, bc
		ex	de, hl
		ld	bc, SECT_SZ
		ldir
				
		rst	8		
		defb	54	;write sector
		
	pop	de
	inc	d
	pop	bc
	djnz	IF1FileSaveLoop
	
	rst	8
	defb	52	;close channel (52) or detroy channel (56)
	ret
IF1FileSaveEnd:	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;HL = destination buffer, B = count of sectors, DE = track/sector
;Out: A = error code, 0=OK
ReadDiskSectors:
	push bc
		push hl
		push de
		call ReadOneDiskSector
		pop de
		pop hl

		inc d
		inc h
	pop bc
	
	ld	a, (RWTSRes)
	or	a
	ret nz
	
	djnz ReadDiskSectors
	ret

;HL = source buffer, B = count of sectors, DE = track/sector
;Out: A = error code, 0=OK
WriteDiskSectors:
	push bc
		push hl
		push de
		call WriteOneDiskSector
		pop de
		pop hl

		inc d
		inc h
	pop bc
	
	ld	a, (RWTSRes)
	or	a
	ret nz
	
	djnz WriteDiskSectors
	ret
	

;Reads disk catalog
ReadCatalogTrack:
	ld hl, TrackBuf
	ld de, 0
	ld b, SPT
		
	call ReadDiskSectors		
	ret
	
;A = track
SeekTrack:
	IFUSED
	ld	(RWTSTrack), a
	ld 	a, RWTS_CMD_SEEK
	jp	RWTS	
	ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;IN: DE = file name to search in cache, HL = file cache table, C = item count
FindCache:
	push	bc
	ld	b, NAMELEN
	call	StrCmp	;find the file to wich this extension belongs
	pop	bc
	ret	z

	djnz	CacheNotFinished
	or	c
	ret

CacheNotFinished:
	push	bc
	ld	bc, CACHE_SZ
	add	hl, bc	;to the next cache line
	pop	bc
	jr	FindCache

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;ld	ix, (SelFileCache)
ReadFileHeader:
	ld	a, (ix + CACHE_FLAG)
	and	CACHE_FLAG_HDR_READ
	ret	nz		;return if already read

	ld	l, (ix + CACHE_FIRST_AU)
	ld	h, (ix + CACHE_FIRST_AU + 1)
	ld	a, h
	or	l
	jr	z, ReadHeaderEnd
	
	call	AU2TS
	ld	d, b
	ld	e, c
	ld	hl, DataBuf	
	push	ix
	push	ix
		call	ReadOneDiskSector
	pop	hl
	pop	ix
	
	push	hl
		ld	hl, DataBuf
		call	IsFileHeaderValid
	pop	hl
	or	a
	jr	z, ReadFileHeaderIsTextFile
	
	ld	bc, CACHE_HDR
	add	hl, bc
	ex	hl, de
	ld	hl, DataBuf
	ld	bc, HDR_SZ
	ldir
	
	;For text files, read file size as reported by BDOS, since we don't have a header.
	ld	a, BYTE_TYPE
	cp	(ix + CACHE_HDR + HDR_TYPE)
	jr	nc, ReadHeaderEnd
	
ReadFileHeaderIsTextFile:	
	push	ix	
	push	ix
	pop	hl
		call	GetFileSize		
	pop	ix	
	ld	(ix + CACHE_HDR + HDR_LEN), l
	ld	(ix + CACHE_HDR + HDR_LEN + 1), h	
	ld	a, TEXT_TYPE
	ld	(ix + CACHE_HDR + HDR_TYPE), a
	
ReadHeaderEnd:
	ld	a, (ix + CACHE_FLAG)
	or	CACHE_FLAG_HDR_READ
	ld	(ix + CACHE_FLAG), a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Checks if the file header is valid. For now it checks to not have all 0s.
;Some binary files can be mistakend for Program files, because the first byte is 0 == PROG_TYPE.
;In: HL = header
;Out: A > 0 if valid
IsFileHeaderValid:
	IFUSED
	xor	a
	ld	b, HDR_SZ
IsFileHeaderValidLoop:		
	or	(hl)
	inc	hl
	djnz	IsFileHeaderValidLoop
	
	ret
	ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;IN: HL = address from IF1 to call
IF1Call:
	LD   (HD11), HL
	RST  8
	DEFB 50
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Load a program from disk
;IN: HL = file name addr
LoadProgram:
	LD   (FSTR1), HL
	LD   H, 0
	LD   L, NAMELEN
	LD   (NSTR1), HL
	LD	 A, (RWTSDrive)
	INC  A			;Adapt for BASIC drive number
	LD   L, A
	LD   (DSTR1), HL
	LD   HL, LOAD_ADDR
	CALL IF1Call
	RET
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetFastKeys:
	ld	a, 10
	ld	(REPDEL), a
	ld	a, 1
	ld	(REPDEL+1),a

	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Reads the error message string from IF1 ROM.
GetErrMsg:
	inc	a
	ex	af, af'

	ld		hl, IF1Paged	;page-in IF1
	jp	IF1Call

IF1Paged:
	ld	hl, ERRMSG
	ex	af, af'
	or	a
	jr	z, SaveMsg

	ld	b, 0
SearchMsgEnd:
	bit	7, (hl)
	inc	hl
	jr	z, SearchMsgEnd

	inc	b
	cp	b
	jr	nz, SearchMsgEnd

SaveMsg:
	ld	de, DataBuf
CopyMsg:
	ld	a, (hl)
	bit	7, a
	ld	(de), a
	inc	hl
	inc	de
	jr	z, CopyMsg

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;RWTS routine I/O block
RWTSParams:
RWTSBlockType	DEFB	1					;?
RWTSDrive	DEFB	DRIVE_A_CPM			;NOT like BASIC (0,1,2), just 0,1.
RWTSVolNo	DEFB	0					;?
RWTSTrack	DEFB	0
RWTSSector	DEFB	0
RWTSDMA		DEFW	0
RWTSExtBuf	DEFW	$2932

;The emulators don't like the short times set in the parameter table, but the real hardware works fine and faster.
	IFDEF _REAL_HW_
RWTSPrmTbl	DEFW	BasPrmTbl	;$1f2a
	ELSE
RWTSPrmTbl	DEFW	$1f2a	
	ENDIF
	
RWTSCmd		DEFB	RWTS_CMD_READ
;Results
RWTSRes		DEFB	0
RWTSResVolNo	DEFB	0
RWTSResTmp	DEFB	0, 0, 0, 0, 0

;Param. table, usualy found in ROM.
	IFDEF _REAL_HW_
BasPrmTbl:

;In one user case, these short time parameters caused issues, the loading from disk was much slower instead of faster.
	;DEFINE _STANDARD_DRIVE_PARAM_
	IFDEF _STANDARD_DRIVE_PARAM_
PrmDevType	DEFB	$01
PrmStepRate	DEFB	$0D	;(milisec)
PrmHeadLoad	DEFB	$23	;(milisec)
PrmSpinUp	DEFB	$64	;(1/100 sec)	
	ELSE ;Reduce original parameters by a factor, instead of setting all to 1s, to increase compatibility with some bad drivers. Minimal values worked for me, but might not work for some users, depending on drive.
PrmFastFactor	EQU	5
PrmDevType	DEFB	$01
PrmStepRate	DEFB	$0D/PrmFastFactor	;(milisec)
PrmHeadLoad	DEFB	$23/PrmFastFactor	;(milisec)
PrmSpinUp	DEFB	$64/PrmFastFactor	;(1/100 sec)	
	ENDIF
	
PrmIntrlvTbl	DEFW	$1F30	;InterleaveTbl
;InterleaveTbl   DEFB	1, 3, 5, 7, 9, 11, 13, 15, 2, 4, 6, 8, 10, 12, 14, 16
	ENDIF

	endif