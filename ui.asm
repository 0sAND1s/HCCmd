;UI related functions

	ifndef	_UI_
	define	_UI_

	include	"hccfg.asm"

COL		EQU 23728
LINE		EQU 23729               ;Coordinates
LineCol		EQU COL
CODE		EQU 23681               ;Char to print

CPM_FNT_ADDR	EQU $25AB
	
PORT_ZX		EQU	$FE

;COLORS
CLR_BLACK	EQU	0
CLR_BLUE	EQU	1
CLR_RED		EQU	2
CLR_MAGENTA	EQU	3
CLR_GREEN	EQU	4
CLR_CYAN	EQU	5
CLR_YELLOW	EQU	6
CLR_WHITE	EQU	7
CLR_BRIGHT	EQU	%01000000
CLR_FLASH	EQU	%10000000

;PAPER
PAPER_BLACK	EQU (CLR_BLACK << 3)
PAPER_BLUE	EQU (CLR_BLUE << 3)
PAPER_RED	EQU (CLR_RED << 3)
PAPER_MAGENTA	EQU (CLR_MAGENTA << 3)
PAPER_GREEN	EQU (CLR_GREEN << 3)
PAPER_CYAN	EQU (CLR_CYAN << 3)
PAPER_YELLOW	EQU (CLR_YELLOW << 3)
PAPER_WHITE	EQU (CLR_WHITE << 3)

;INK
INK_BLACK	EQU CLR_BLACK
INK_BLUE	EQU CLR_BLUE
INK_RED		EQU CLR_RED
INK_MAGENTA	EQU CLR_MAGENTA
INK_GREEN	EQU CLR_GREEN
INK_CYAN	EQU CLR_CYAN
INK_YELLOW	EQU CLR_YELLOW
INK_WHITE	EQU CLR_WHITE


SCR_ATTR_ADDR		EQU 22528
SCR_ADDR		EQU 16384
SCR_PIX_LEN		EQU 6144
SCR_ATTR_LEN		EQU 768
SCR_LEN			EQU SCR_PIX_LEN + SCR_ATTR_LEN
SCR_BYTES_PER_LINE	EQU 32

SCR_COLS		EQU 64
SCR_LINES		EQU 24

;used for file names list positioning
LST_LINES_CNT		EQU	21
LST_FIRST_LINE		EQU	1
LST_LAST_LINE		EQU LST_FIRST_LINE + LST_LINES_CNT
LST_PROG_INFO		EQU LST_FIRST_LINE
LST_DISK_INFO		EQU LST_PROG_INFO + 3
LST_FILE_INFO		EQU LST_DISK_INFO + 3
LST_LINE_MSG		EQU LST_FILE_INFO + 6
LST_FIRST_COL		EQU	16
LST_MAX_FILES		EQU LST_LINES_CNT * 4
LST_MAX_FILES_ON_DISK	EQU 128

;key codes
KEY_ESC		EQU	7
KEY_LEFT	EQU	8
KEY_RIGHT	EQU	9
KEY_DOWN	EQU	10
KEY_UP		EQU	11
KEY_BACKSP	EQU	12
KEY_ENTER	EQU	13
KEY_CTRL	EQU	14

SCR_DEF_CLR	EQU INK_CYAN | PAPER_BLACK | CLR_BRIGHT
SCR_SEL_CLR	EQU INK_CYAN | PAPER_BLUE | CLR_BRIGHT
SCR_LBL_CLR	EQU INK_CYAN | PAPER_BLUE
SCR_ASK_CLR	EQU SCR_DEF_CLR | CLR_FLASH | CLR_BRIGHT
SCR_TAG_CLR	EQU INK_YELLOW | PAPER_BLACK | CLR_BRIGHT
SCR_PROG_CLR	EQU INK_RED | PAPER_BLACK | CLR_BRIGHT

;Special formating chars
CHR_CR		EQU	13
CHR_LF		EQU	10
CHR_TAB		EQU	09


;Semi-graphical chars
;           UC
;     UL +H-+--+UR
;        |  |  |
;     ML +--+--+MR
;        V C|  |
;     LL +--+--+LR
;           DC
CHR_GRID        EQU 127
CHR_V           EQU 128
CHR_MR          EQU 129
CHR_UR          EQU 130
CHR_DL          EQU 131
CHR_DC          EQU 132
CHR_UC          EQU 133
CHR_ML          EQU 134
CHR_H           EQU 135
CHR_C           EQU 136
CHR_LR          EQU 137
CHR_UL          EQU 138
CHR_FULL        EQU 139
CHR_HALF        EQU 140

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Return read char in A
ReadChar:
	rst 08
	DEFB 27
	ret

;Checks if a key is pressed
;Cy=1 if key is pressed
KbdHit:
	rst 08
	DEFB 32
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitFonts:
	IFUSED
	;page-in CPM ROM to get fonts
	di
	ld	a, HC_CFG_ROM_CPM
	out	(HC_CFG_PORT), a
	
	ld	hl, CPM_FNT_ADDR
	ld	de, FontTable
	ld	bc, 872
	ldir
	
	;restore BASIC ROM
	ld	a, HC_CFG_ROM_BAS
	out	(HC_CFG_PORT), a
	ei

	ret
	ENDIF

ClrScr:
	ld	hl, SCR_ADDR
	ld	d, h
	ld	e, l
	inc	de
	ld	bc, SCR_PIX_LEN - 1
	ld	(hl), 0
	ldir

	inc 	hl
	inc	de

	ld	bc, SCR_ATTR_LEN - 1
	ld	(hl), SCR_DEF_CLR
	ldir

	;also set border color
	ld	a, SCR_DEF_CLR >> 3
	out	(PORT_ZX), a

	ld	a, SCR_DEF_CLR
	ld	(23624), a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;IN: HL = str. addr, DE = line/col, str ends with last char bit 7 set
PrintStr:
	ld	a, (hl)
	cp	' '
	jr	nc, GoodChar
	ld	a, '.'
GoodChar:
	bit	7, a
	res	7, a
	ld	(CODE), a
	ld	(LineCol), de
	ex	af, af'
	exx
	push	hl
	call 	PrintChar
	pop	hl
	exx
	ex	af, af'
	ret	nz

	inc	e
	inc	hl

	;ld	a, e
	;cp	COL_CNT
	;jr	c, PrintStr
	;ld	e, 0
	;inc	d

	jr	PrintStr

;Print char with length in B.
PrintStrN:
	IFUSED
	ld	a, (hl)
	ld	(CODE), a
	ld	(LineCol), de
	push	bc
	push	hl
		call 	PrintChar
	pop	hl
	pop	bc
	ld	de, (LineCol)
	inc	e
	inc	hl
	djnz	PrintStrN
	
	ret
	ENDIF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;IN: HL = string, DE = coords, A = color
PrintStrClr:
	ld	(StrClr), a
	push	de
		call	PrintStr
	pop	hl
	;get string len.
	ld	a, e
	sub	l
	rra
	ex	af, af'
		;line * 32
		ld	a, h
		rla
		rla
		ld	de, 0
		rla
		rl	d
		rla
		rl	d
		rla
		rl	d
		ld	e, a

		ld	h, 0
		add	hl, de
		ld	de, SCR_ATTR_ADDR
		add	hl, de
	ex	af, af'
	ld	c, a
	ld	b, 0
	ld	d, h
	ld	e, l
	inc 	de
StrClr	EQU	$ + 1
	ld	(hl), SCR_SEL_CLR
	ldir
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;IN: B = length, D = line, E = col, A = char, C = horiz/vertical
DrawLine:
	ld	(CODE), a

	jr	c, VertDir
	ld	a, $1C
	jr	StoreDir
VertDir:
	ld	a, $14
StoreDir:
	ld	(LineDir), a

DrawLineLoop:
	ld	(LineCol), de
	push	de
		exx
		push	hl
		call 	PrintChar
		pop	hl
		exx
	pop	de
LineDir:
	inc	e
	djnz	DrawLineLoop

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawHLines:	
	ld	de, 0
	ld	b, 64
	ld	a, CHR_H
	or	a	
	call	DrawLine
	
	ld	de, LST_LAST_LINE << 8
	ld	b, 64
	ld	a, CHR_H
	or	a	
	call	DrawLine	
	
	ld	b, 4
	ld	de, LST_FIRST_COL
DrawUpperIntersectLoop:	
	push	bc
	push	de
		ld	a, CHR_UC
		call	DrawIntersect
	pop	de
	pop	bc
	ld	hl, NAMELEN+1
	add	hl, de
	ex	de, hl
	djnz	DrawUpperIntersectLoop
	
	ld	b, 4
	ld	de, (LST_LAST_LINE << 8) | LST_FIRST_COL
DrawLowerIntersectLoop:	
	push	bc
	push	de
		ld	a, CHR_DC
		call	DrawIntersect
	pop	de
	pop	bc
	ld	hl, NAMELEN+1
	add	hl, de
	ex	de, hl
	djnz	DrawLowerIntersectLoop
			
	ret	


DrawIntersect:
	ld	hl, LineCol
	ld	(hl), e
	inc	hl
	ld	(hl), d
	dec	hl
	ld	(CODE), a
	push	hl
	call	PrintChar
	pop	hl
	inc	(hl)
	ld	a, CHR_H
	ld	(CODE), a
	call	PrintChar
	ret


DrawVLines:
	ld	b, 4
	ld	de, (LST_FIRST_LINE << 8) | LST_FIRST_COL
DrawVLinesLoop:
	push 	bc
	push	de
		ld	b, LST_LINES_CNT
		ld	a, CHR_V
		scf
		call	DrawLine
	pop	de
	pop	bc
	ld	a, e
	add	NAMELEN+1
	ld	e, a
	djnz	DrawVLinesLoop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;IN: A = color mask
DrawCursor:
	ld	de, (CursorAddr)
	ld	b, (NAMELEN + 1)/2
DrawCursorLoop:
	ld	(de), a
	inc	de
	djnz	DrawCursorLoop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;IN:	A = file index for the newly selected file.
MoveCursor:	
	;clear old cursor			
	push	af			
		xor	a
		call	DrawFileNameColor	
	pop	af
	
	;draw new cursor
	ld	a, (SelFile)
	call	GetCursorAddr	
	ld	a, (SelFile)
	call	CalcFileCache
	ld	a, 1
	call	DrawFileNameColor

	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;IN: A=1 for selected color/0 for unselected color. SelFileCache = file cache entry. (CursorAddr) = cursor address.
;Color is set to one of 4 options: 
;normal - CYAN ink
;tagged - RED ink
;program type - MAGENTA ink
;selected - GREEN background over existing ink color
DrawFileNameColor:	
	ex	af, af'			;Save selected file flag.
	
	ld	ix, (SelFileCache)	
	
	;Check if file was tagged.
	ld	a, (ix + CACHE_FLAG)
	and	CACHE_FLAG_TAGGED
	jr	z, DrawFileNameColorNotTagged
	
	ld	l, SCR_TAG_CLR
	jr	DrawFileNameColorDoIt
	
DrawFileNameColorNotTagged:
	;Check if file header was read and file type is program.
	ld	a, (ix + CACHE_FLAG)
	and	CACHE_FLAG_HDR_READ
	jr	z, DrawFileNameColorNotProgram
	ld	a, (ix + CACHE_HDR + HDR_TYPE)	
	cp	PROG_TYPE
	jr	nz, DrawFileNameColorNotProgram
	ld	l, SCR_PROG_CLR
	jr	DrawFileNameColorDoIt
	
DrawFileNameColorNotProgram:
	ld	l, SCR_DEF_CLR
	
DrawFileNameColorDoIt:
	ex	af, af'	
	or	a
	ld	a, l
	jr	z, DrawFileNameColorDoItNotSelected	
	or	PAPER_BLUE
	
DrawFileNameColorDoItNotSelected:	
	call	DrawCursor
	
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;IN:	A = file idx.
GetCursorAddr:
	;File idx / SCR_LINES => cursor line & column
	ld	l, a
	ld	h, 0
	ld	c, LST_LINES_CNT
	call	Div				;HL = file column, A = line

	;cursor addr = SCR_ATTR_ADDR + (line + LST_FIRST_LINE) * SCR_BYTES_PER_LINE + column * NAMELEN/2
	add	LST_FIRST_LINE


	ld	d, h
	ld	e, l
	ld	hl, 0

	;line*32
	rla
	rla
	rla
	rla
	rl h
	rla
	rl h
	ld l, a


	;col * 6
	push	hl				;save line * 32
		ld	a, (NAMELEN + 1)/2
		call	Mul			;HL = column * 12/2
	pop	de
	add	hl, de

	ld	de, LST_FIRST_COL/2
	ld	bc, SCR_ATTR_ADDR
	add	hl, de
	add	hl, bc
	ld	(CursorAddr), hl		
	
	ret	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PrintChar:
    ld	de, (LineCol)

	;calculate 64 column screen address
	;IN: D = line, E = col
	;OUT: HL = screen address

    SRL     E                                       ;col = col/2
    RR      C                                       ;mark odd/even column
    LD      A, D                            ;A = line
    AND 24                                  ;keep only %00011000
    ld	hl, SCR_ADDR
    OR      h							;add screen start address
    LD      H, A                            ;save H
    LD      A, D                            ;A = line
    AND 7                                   ;keep only %00000111
    RRCA                                    ;%10000011
    RRCA                                    ;%11000001
    RRCA                                    ;%11100000
    OR      E                                       ;add column
    LD      L, A                            ;HL = screen address

PrintChar3:
    ;get font address
    PUSH HL
        XOR A
        LD  H, A
        LD  A, (CODE)
        SUB ' '
        LD  L, A
        ADD     HL, HL                  ;char code = char code * 8
        ADD     HL, HL                  ;i.e. offset into font table
        ADD     HL, HL
        LD      DE, FontTable             ;get font table
        ADD     HL, DE
        EX      DE, HL                  ;DE = our char font address
    POP     HL


    ;print a char
    LD      B, 8                            ;char height is 8 lines
PrintCharLine:
        LD      A, (DE)                         ;load char line in A

        BIT     7, C                            ;restore correct position of the 2 chars in cell if on odd column
        JR  	NZ, NoTurn

        RLCA
        RLCA
        RLCA
        RLCA
        JR      Store
NoTurn:
        OR (HL)
Store:
        LD (HL), A

        INC     DE                                      ;next char line in font table
        INC     H                                       ;next char line on screen
    DJNZ PrintCharLine                  ;last line of char?

    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;DE = screen coord; Output: DataBuf == read string, terminated at ' ' | $80
ReadString:
	ld	hl, FileData
	push	de
	pop	ix
	
ReadStringLoop:
	push	de
	push	hl
		call ReadChar
	pop	hl
	pop	de
	
	cp	KEY_ENTER
	ret z
	
	cp  KEY_BACKSP
	jr	nz, ReadStrChar		
	
	push hl
	ld   bc, FileData+1
	sbc	 hl, bc
	pop  hl
	jr   c, ReadStrPrint
	
	dec	de
	dec	hl
	ld	(hl), ' '
	jr	ReadStrPrint
	
ReadStrChar:
	cp	' '
	jr	c, ReadStringLoop
	cp	CHR_HALF
	jr	nc, ReadStringLoop
	
	;Check end of string and go back if found.	
	ld	b, (hl)
	bit 7, b
	jr	nz, ReadStrPrint
	
	ld	(hl), a	
	inc	hl
	inc	de
	
ReadStrPrint:
	push	hl
	push	de
	ld	hl, FileData
	push	ix
	pop	de
	call	PrintStr
	pop	de
	pop	hl	
		
	jr	ReadStringLoop
	
ClearNMsgLines:	
	ld	de, LST_LINE_MSG + 1 << 8
ClearNMsgLinesLoop:	
	push	de
	push	bc
	ld	hl, MsgClear
	ld	a, SCR_DEF_CLR
	call	PrintStrClr
	pop	bc
	pop	de
	inc	d
	djnz	ClearNMsgLinesLoop
	
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Byte2HexHex:		
	push	hl
		push	de
			ld	a, (hl)
			call	ByteToHex		
		pop	ix
		
		ld	(ix), d
		ld	(ix+1), e
		ld	d, ixh
		ld	e, ixl
		inc	de
		inc	de
	pop	hl
	inc	hl
	
	ret
		
Byte2HexChar:	
	;The text viewer goes down one line when finding a CR char, so we must replace the CR char.
	ld	a, CHAR_CR
	cp	(hl)
	jr	nz, Bin2HexLineLoopTextCopy
	
Bin2HexLineLoopTextReplace:	
	ld	a, '.'
	ld	(hl), a
	
Bin2HexLineLoopTextCopy:	
	ldi
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HEX_COLUMNS	EQU	16

;Line structure, allowing 2 hex digits per screen cell, for using the attribute color as cursor.
;Max file size is 636KB = $9F000
;123456||12345678||12345678||12345678||12345678||0123456789ABCDEF
;HIOFFS:_11223344__55667788__11223344__55667788__0123456789ABCDEF

Bin2HexLine:
	;Offset
	push	hl
		push	de
			ld	a, (HexOffsetHi)
			call	ByteToHex
		pop	ix		
		
		ld	(ix), d
		ld	(ix+1), e
		inc	ix
		inc	ix
		
		ld	hl, (HexOffset)
		call	Word2Hex				
				
		ld	(ix), h
		ld	(ix+1), l
		ld	(ix+2), d
		ld	(ix+3), e
		
		ld	d, ixh
		ld	e, ixl	
	pop	hl
	push	hl
	
	inc	de
	inc	de
	inc	de
	inc	de
	ld	a, ':'
	ld	(de), a
	inc	de
	ld	a, ' '
	ld	(de), a
	inc	de
	
	;Hex part	
	ld	c, 4
Bin2HexLineLoopHex1:	
	push	bc
	ld	b, 4	
Bin2HexLineLoopHex:
	call	Byte2HexHex	
	djnz	Bin2HexLineLoopHex
	
	ld	a, ' '
	ld	(de), a
	inc	de
	ld	(de), a
	inc	de
	
	pop	bc
	dec	c
	jr	nz, Bin2HexLineLoopHex1	
	
	;ld	ixh, d
	;ld	ixl, e
	;ld	(ix - (HEX_COLUMNS/2)*3 - 1), a
	
	;String part
	pop	hl	
Bin2HexLineText:	
	;just to not alter B with LDI, set C to something > 16
	ld	bc, (HEX_COLUMNS << 8) | HEX_COLUMNS*2
Bin2HexLineLoopText:
	call	Byte2HexChar
	djnz	Bin2HexLineLoopText
	ret
		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Converts binary buffer at HL to hex string at DE with length in BC.
Bin2HexStr:		
	push	hl
		ld	ix, (FileBlocksIdxPos)		
		ld	l, (ix)
		ld	h, (ix+1)		
		
		ld	a, REC_SZ
		push	de
		push	bc
		ex	de, hl
		call	Mul
		pop	bc
		pop	de
		
		ld	(HexOffset), hl
		xor	a
		ld	(HexOffsetHi), a
	pop	hl
	
	;Calculate the number of full lines by dividing BC to 16.	
	xor	a
	
	rr	b
	rr	c
	rra
	
	rr	b
	rr	c
	rra

	rr	b
	rr	c
	rra

	rr	b
	rr	c
	rra
	
	rra
	rra
	rra
	rra
	
	or	a
	jr	z, Bin2HexWholeLine
	inc	bc
	
Bin2HexWholeLine:	
	ex		af, af'		;Keep reminder
	
Bin2HexStrLoop:	
	push	bc		
		call	Bin2HexLine
		push	hl
			ld	hl, (HexOffset)
			ld	bc, HEX_COLUMNS
			add	hl, bc			
			ld	(HexOffset), hl
			ld	a, (HexOffsetHi)
			adc	0
			ld	(HexOffsetHi), a
		pop	hl
	pop	bc
	
	dec	bc
	ld	a, b
	or	c
	jr	nz, Bin2HexStrLoop

	;Set remaining imcomplete line.	
	;Exit if last line is empty.
	ex	af, af'	
	or	a
	ret	z	
	
	;TODO: Clean up part of the line that is past the end of file.
		
	
	ret
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;IN: IX = dest count as string, HL = message to display
;OUT: Z=1 if confirmed, B = how many files were selected (possibly 0)
PrintSelectedFilesMsg:
	push	hl
		call	CountTaggedFiles		
		or	a
		push	af
		jr	nz, PrintSelectedFilesMsgFilesSelected
		inc	a				;Set attributes for just 1 file, the one under cursor.
	
PrintSelectedFilesMsgFilesSelected:	
		ld	de, PRN_BUF
		ld	l, a
		ld	h, 0	
		call	Byte2Txt		
		ld	a, (PRN_BUF + 0)
		ld	(ix), a
		ld	a, (PRN_BUF + 1)
		ld	(ix+1), a
		ld	a, (PRN_BUF + 2)
		ld	(ix+2), a
	pop	af
	pop	hl
	push	af	
	ld	de, LST_LINE_MSG + 1 << 8
	ld	a, SCR_ASK_CLR
	call	PrintStrClr
	ld	hl, MsgAreYouSure
	ld	de, LST_LINE_MSG + 2 << 8
	ld	a, SCR_ASK_CLR
	call	PrintStrClr
	call	ReadChar
	push	af
		ld	b, 2
		call	ClearNMsgLines
	pop	af
	cp	CONFIRM_KEY
	pop	bc
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HexOffsetHi	DEFB	$AB
HexOffset	DEFW	$CDEF

   	endif