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

DRIVE_CUR_BAS	EQU 0
DRIVE_A_BAS		EQU	1
DRIVE_B_BAS		EQU	2
DRIVE_A_CPM		EQU	0
DRIVE_B_CPM		EQU	1
;Disk geometry stuff
SPT				EQU	16			;sectors per track
SECT_SZ			EQU	256			;sector size in bytes
TRACK_CNT		EQU	80			;track count
HEAD_CNT		EQU	2			;disk face count
AU_SZ			EQU	2048		;allocation unit size in bytes (8 sectors, half of a track)
EXT_SZ			EQU	32			;directory entry size
DIR_TRK_CNT		EQU	1			;tracks rezerved for directory
EXT_AU_CNT		EQU 8			;allocation units in one extension
SPAL			EQU	(AU_SZ/SECT_SZ);sectors per allocation unit
MAX_EXT_CNT		EQU	(SPT * DIR_TRK_CNT * SECT_SZ / EXT_SZ);maximum directory entries
MAX_FREE_AU_CNT		EQU	((TRACK_CNT * HEAD_CNT - DIR_TRK_CNT) * SPT * SECT_SZ)/AU_SZ ;max free allocation units (318)
REC_SZ			EQU 128			;cp/m record size
DEL_MARKER		EQU	$E5
EOF_MARKER		EQU	$1B


;Extension structure (directory entry)
EXT_DEL_FLAG	EQU	0
EXT_NAME		EQU 1
EXT_IDX			EQU 12
EXT_S1			EQU 13
EXT_S2			EQU 14
EXT_RC			EQU	15
EXT_AU0			EQU	16
EXT_AU1			EQU	18
EXT_AU2			EQU	20
EXT_AU3			EQU	22
EXT_AU4			EQU	24
EXT_AU5			EQU	26
EXT_AU6			EQU	28
EXT_AU7			EQU	30
EXT_SIZE		EQU 32

;FCB structure
FCB_DRIVE		EQU 0
FCB_NAME		EQU EXT_NAME
FCB_EX_IDX		EQU EXT_IDX
FCB_S1			EQU EXT_S1
FCB_S2			EQU EXT_S2
FCB_RC			EQU	EXT_RC
FCB_AU			EQU	EXT_AU0
FCB_CR			EQU	32
FCB_R0			EQU 33
FCB_R1			EQU 34
FCB_R2			EQU 35
FCB_SIZE		EQU 36



;System variables for disk
DSTR1			EQU	$5CD6		;drive
FSTR1			EQU	$5CDC		;file name
NSTR1			EQU	$5CDA		;name length
HD11			EQU	$5CED		;BDOS argument
COPIES			EQU	$5CEF		;BDOS function

ERRSP			EQU $5C3D
ERRNR			EQU $5C3A
ERRMSG			EQU	$0260

PRN_BUF			EQU	23296

;STR_COPYRIGHT	EQU	$1539

REPDEL			EQU	23561
REPPER			EQU	23562
PIP				EQU	23609


;RWTS routine commands
RWTS_CMD_POS	EQU	0			;position head
RWTS_CMD_READ	EQU	1			;read sector
RWTS_CMD_WRITE	EQU	2			;write sector
RWTS_CMD_FMT	EQU	4			;format all tracks


;File name stuff
NAMELEN			EQU	11			;name length
RO_POS			EQU	8			;read-only attribute position in name
SYS_POS			EQU	9			;system attribute position in name

;File types (first byte in header)
PROG_TYPE		EQU	0			;program
NUMB_TYPE		EQU	1			;number array
CHAR_TYPE		EQU	2			;char array
BYTE_TYPE		EQU	3			;bytes
TEXT_TYPE		EQU	4			;text, >= 4

;File header offsets
HDR_TYPE		EQU	0
HDR_LEN			EQU 1
HDR_ADDR		EQU 3
HDR_PLEN		EQU	5
HDR_LINE		EQU 7
HDR_SZ			EQU	9

;BASIC disk channel structure
CH_RW_FLAG		EQU 11
CH_FCB			EQU	12
CH_DATA			EQU	50
CH_DMA			EQU CH_DATA - CH_FCB	;offset of DMA from start of FCB

CACHE_NAME		EQU	0					;11B
CACHE_FIRST_AU	EQU	NAMELEN				;2B
CACHE_AU_CNT	EQU	CACHE_FIRST_AU + 2	;2B
CACHE_FLAG		EQU CACHE_AU_CNT + 2	;1B
CACHE_HDR		EQU	CACHE_FLAG + 1		;9B
CACHE_SZ		EQU	25					;11 + 2 + 2 + 1 + 9

LOAD_ADDR		EQU	2625		;address of the load procedure in IF1 ROM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF1Init:
	rst		08
	defb	49		;create system variables
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
	ld (RWTSDMA), hl
	ld (RWTSTrack), de
	;ld (RWTSDrive), a
	ld a, RWTS_CMD_READ
	jr	RWTS
	
;D = sector, E = track
;HL = dma
WriteOneDiskSector:
	ld (RWTSDMA), hl
	ld (RWTSTrack), de
	;ld (RWTSDrive), a
	ld a, RWTS_CMD_WRITE
	jr	RWTS	
	
FormatDisk:
	ld		hl, DataBuf
	ld		(hl), DEL_MARKER
	ld 		(RWTSDMA), hl
	ld 		a, RWTS_CMD_FMT
	call	RWTS
	ld		a, (RWTSRes)
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Allocation unit no. to track/sector
;Formula: T=(AllocUnit*SPAL)/SPT; Sect=T mod SPT; Track=T/2 (2 disk faces); Head=T mod 2
;IN:  HL=alloc. unit no.
;OUT: B=sector; C=track (head is determined by the sector number)
AU2TS:
	ld c, SPT/SPAL
	call Div					;A = sector
	push af
		/*
		ld c, HEAD_CNT
		call Div				;L = track, A = head (0 or 1)
		*/
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
;		C = no. of records used in ext.
;		HL = first alloc. unit no.
;		DE = last alloc. unit no.
CheckExtAlloc:
	push ix
		ld bc, EXT_RC
		add ix, bc
		ld c, (ix)			;save rec. no.
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
;Output: DataBuf = used block count (2 bytes), used block numbers (2 bytes each)
ReadUsedBlocksList:
	ld		ix, TrackBuf			;source buffer
	ld		hl, DataBuf 			;destination buffer
	ld		bc, MAX_FREE_AU_CNT		;loop counter
	ld		de, 2					;counter of used blocks, start with 2
	ld		(hl), e
	inc		hl
	ld		(hl), d
	inc		hl
	
	;Add blocks 0 and 1 for directory
	ld		de, 0
	ld		(hl), e
	inc		hl
	ld		(hl), d
	inc		hl
	
	inc		de
	ld		(hl), e
	inc		hl
	ld		(hl), d
	inc		hl
	
ReadUsedBlocksLoop:	
	xor		a
	cp		(ix)
	jr		nz, ReadUsedBlocksSkip2;skip dir entry because it's not valid
	
	push	ix
	push	bc
		ld		b, EXT_AU_CNT
		ld		de, EXT_AU0
		add		ix, de
		
ReadUsedBlocksLoop2:		
		ld		e, (ix)
		ld		d, (ix+1)
		ld		a, e
		or		d
		jr		z, ReadUsedBlocksSkip;end dir entry reading when the AU number is 0
		
		ld		(hl), e
		inc		hl
		ld		(hl), d
		inc		hl
		
		inc		ix
		inc		ix
		
		ld		de, (DataBuf)
		inc		de
		ld		(DataBuf), de
		
		djnz	ReadUsedBlocksLoop2
		
	
ReadUsedBlocksSkip:	
	pop		bc
	pop		ix
ReadUsedBlocksSkip2:	
	ld		de, EXT_SZ
	add		ix, de

	dec		bc
	ld		a, b
	or		c
	jr		nz, ReadUsedBlocksLoop
	
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Reads 8 sectors for an AU
;HL = block number, DE = destination buffer
ReadFSBlock:
	push	de
		call	AU2TS		;B=sector, C=track
	pop		hl				;HL=dest
	
	ld		d, b
	ld		e, c	
	ld		b, SPAL

ReadFSBlockLoop:	
	call	ReadDiskSectors
	or		a
	ret		nz
	
	inc		h				;+256 bytes
	inc		d				;+1 sector
	djnz	ReadFSBlockLoop
	
	ret


;Write 8 sectors for an AU
;HL = block number, DE = source buffer
WriteFSBlock:
	push	de
		call	AU2TS		;B=sector, C=track
	pop		hl				;HL=dest
	
	ld		d, b
	ld		e, c	
	ld		b, SPAL

WriteFSBlockLoop:	
	call	WriteDiskSectors
	or		a
	ret		nz
	
	inc		h				;+256 bytes
	inc		d				;+1 sector
	djnz	WriteFSBlockLoop
	
	
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Copies the catalog track and the allocated blocks from one disk to another.
CopyDisk:
	;Get list of used blocks in current disk, stored in DataBuf, max 632 bytes
	call	ReadUsedBlocksList
	
	ld		bc, (DataBuf)		;block count, max 318
	ld		a, b
	or		c
	ret		z
	
	ld		ix, DataBuf + 2
	ld		de, DataBuf + 632
	
CopyDiskLoop:	
	push	bc
	push	de
	
	ld		l, c
	ld		h, b
	ld		de, MsgBlocksLeft
	call	Byte2Txt
	ld		hl, MsgBlocksLeft
	ld		de, LST_LINE_MSG + 1 << 8
	ld		a, SCR_DEF_CLR | CLR_FLASH
	call	PrintStrClr
	
	pop		de
	pop		bc
	push	bc
	push	de
	
		ld		l, (ix)
		ld		h, (ix+1)
		call	ReadFSBlock			;Stop on error?
		
	pop		de
	push	de
		;alternate drive
		ld		a, (RWTSDrive)
		xor		%11
		ld		(RWTSDrive), a

		ld		l, (ix)
		ld		h, (ix+1)
		call	WriteFSBlock		;Stop on error?
		
		;alternate drive
		ld		a, (RWTSDrive)
		xor		%11
		ld		(RWTSDrive), a
	pop		de
	pop		bc
	inc		ix
	inc		ix
	
	dec		bc
	ld		a, b
	or		c
	jr		nz, CopyDiskLoop
	
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

;Read a file into a buffer, sector by sector
;In: HL = Name address, DE = buffer
FileLoad:
	push	de
		ld (FSTR1), hl
		ld h, 0
		ld a, (RWTSDrive)
		inc  a			;CP/M drive number to BASIC drive number
		ld	l, a
		ld (DSTR1), hl
		ld l,NAMELEN
		ld (NSTR1), hl
		rst 08
		DEFB 51			;open disk channel

		rst		8		
		defb	53		;read sector
	pop		de
	jr		nc, FileFree

	ld		a, (ix + CH_DATA)
	cp		TEXT_TYPE
	jr		nc, FileLoadNoHeader

FileLoadHeader:
	push	ix
	pop		hl
	ld		bc, CH_DATA + HDR_SZ
	add		hl, bc
	ld		bc, SECT_SZ - HDR_SZ
	ldir

FileReadLoop:
	push	de
		rst		8		
		defb	53		;read sector
	pop		de
	jr		nc, FileFree

FileLoadNoHeader:
	push	ix
	pop		hl
	ld		bc, CH_DATA
	add		hl, bc
	ld		bc, SECT_SZ
	ldir
	jr		FileReadLoop
;Copy routine without FileFree as it messes the buffers, probably moves up variables.
FileLoadEnd:

FileFree:
	push	de
	rst		8
	defb	56			;close channel (52) or detroy channel (56)
	pop		de
	ret


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
	or   a
	ret  nz
	
	;Sync BDOS disk, to avoid disk R/O error on disk change
	push  af
		ld  a, (RWTSDrive)
		call BDOSSelectDisk
		call BDOSInit
	pop   af
	ret



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;IN: DE = file name to search in cache, HL = file cache table, C = item count
FindCache:
	ld		b, NAMELEN
	call	StrCmp			;find the file to wich this extension belongs
	ret		z

	dec		c
	jr		nz, CacheNotFinished
	or		c
	ret

CacheNotFinished:
	ld		bc, CACHE_SZ
	add		hl, bc			;to the next cache line
	jr		FindCache

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;ld		ix, (SelFileCache)
ReadFileHeader:
	ld		a, (ix + CACHE_FLAG)
	or		a
	ret		nz				;return if already read

	ld		l, (ix + CACHE_FIRST_AU)
	ld		h, (ix + CACHE_FIRST_AU + 1)
	ld		a, h
	or		l
	jr		z, ReadHeaderEnd
	call	AU2TS
	ld		d, b
	ld		e, c
	ld		hl, DataBuf	
	push	ix
	push	ix
		call	ReadOneDiskSector
	pop		hl
	pop		ix
	ld		bc, CACHE_HDR
	add		hl, bc
	ex		hl, de
	ld		hl, DataBuf
	ld		bc, HDR_SZ
	ldir
ReadHeaderEnd:
	inc		(ix + CACHE_FLAG)
	ret

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
	INC  A					;Adapt for BASIC drive number
	LD   L, A
	LD   (DSTR1), HL
	LD   HL, LOAD_ADDR
	CALL IF1Call
	RET
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetFastKeys:
	ld		hl, REPDEL
	ld		de, (1 << 8) | 15
	ld		(hl), de

	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetErrMsg:
	inc		a
	ex		af, af'

	ld		hl, IF1Paged			;page-in IF1
	ld		(HD11), hl
	rst		8
	defb	50
	ret								;return after accesing IF1

IF1Paged:
	ld		hl, ERRMSG
	ex		af, af'
	or		a
	jr		z, SaveMsg

	ld		b, 0
SearchMsgEnd:
	bit		7, (hl)
	inc		hl
	jr		z, SearchMsgEnd

	inc		b
	cp		b
	jr		nz, SearchMsgEnd

SaveMsg:
	ld		de, DataBuf
CopyMsg:
	ld		a, (hl)
	bit		7, a
	ld		(de), a
	inc		hl
	inc		de
	jr		z, CopyMsg

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;RWTS routine I/O block
RWTSParams:
RWTSBlockType	DEFB	1
RWTSDrive		DEFB	DRIVE_A_CPM					;NOT like BASIC (0,1,2), just 0,1.
RWTSVolNo		DEFB	0
RWTSTrack		DEFB	0
RWTSSector		DEFB	0
RWTSDMA			DEFW	0
RWTSExtBuf		DEFW	$2932
RWTSPrmTbl		DEFW	$1f2a
RWTSCmd			DEFB	RWTS_CMD_READ
;Results
RWTSRes			DEFB	0
RWTSResVolNo	DEFB	0
RWTSResTmp		DEFB	0, 0, 0, 0, 0

;Param. table, found in ROM, cannot be overriden, it seems the IF1 routine always uses the constants from ROM.
/*
BasPrmTbl:
PrmDevType		DEFB	$01			;$01
PrmStepRate		DEFB	$06;$09		;$0D	(milisec)
PrmHeadLoad		DEFB	$10;$16		;$23	(milisec)
PrmSpinUp		DEFB	$20;$50		;$64	(1/100 sec)
PrmIntrlvTbl	DEFW	InterleaveTbl
InterleaveTbl   DEFB	1, 3, 5, 7, 9, 11, 13, 15, 2, 4, 6, 8, 10, 12, 14, 16
*/

	endif