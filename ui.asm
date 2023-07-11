;UI related functions

	ifndef	_UI_
	define	_UI_

	include	"hccfg.asm"

COL             EQU 23728
LINE            EQU 23729               ;Coordinates
LineCol			EQU	COL
CODE			EQU 23681               ;Char to print

CPM_FNT         EQU $25AB
	
PORT_ZX			EQU	$FE

;COLORS
CLR_BLACK		EQU 0
CLR_BLUE		EQU 1
CLR_RED			EQU 2
CLR_MAGENTA		EQU 3
CLR_GREEN		EQU 4
CLR_CYAN		EQU	5
CLR_YELLOW		EQU	6
CLR_WHITE		EQU	7
CLR_BRIGHT		EQU	%01000000
CLR_FLASH		EQU	%10000000

;PAPER
PAPER_BLACK		EQU (CLR_BLACK << 3)
PAPER_BLUE		EQU (CLR_BLUE << 3)
PAPER_RED		EQU (CLR_RED << 3)
PAPER_MAGENTA	EQU (CLR_MAGENTA << 3)
PAPER_GREEN		EQU (CLR_GREEN << 3)
PAPER_CYAN		EQU	(CLR_CYAN << 3)
PAPER_YELLOW	EQU	(CLR_YELLOW << 3)
PAPER_WHITE		EQU	(CLR_WHITE << 3)

;INK
INK_BLACK		EQU CLR_BLACK
INK_BLUE		EQU CLR_BLUE
INK_RED			EQU CLR_RED
INK_MAGENTA		EQU CLR_MAGENTA
INK_GREEN		EQU CLR_GREEN
INK_CYAN		EQU	CLR_CYAN
INK_YELLOW		EQU	CLR_YELLOW
INK_WHITE		EQU	CLR_WHITE


SCR_ATTR_ADDR	EQU 22528
SCR_ADDR		EQU 16384
SCR_PIX_LEN		EQU	6144
SCR_ATTR_LEN	EQU	768
SCR_LEN			EQU	SCR_PIX_LEN + SCR_ATTR_LEN
SCR_BYTES_PER_LINE	EQU	32

SCR_COLS		EQU	64
SCR_LINES		EQU 24

;used for file names list positioning
LST_LINES_CNT	EQU	21
LST_FIRST_LINE	EQU	1
LST_LAST_LINE	EQU LST_FIRST_LINE + LST_LINES_CNT
LST_PROG_INFO	EQU LST_FIRST_LINE
LST_DISK_INFO	EQU LST_PROG_INFO + 3
LST_FILE_INFO	EQU LST_DISK_INFO + 4
LST_LINE_MSG	EQU LST_FILE_INFO + 6
LST_FIRST_COL	EQU	16
LST_MAX_FILES	EQU LST_LINES_CNT * 4

;key codes
KEY_ESC			EQU	7
KEY_LEFT		EQU	8
KEY_RIGHT		EQU	9
KEY_DOWN		EQU	10
KEY_UP			EQU	11
KEY_BACKSP		EQU 12
KEY_ENTER		EQU	13
KEY_CTRL		EQU	14

SCR_DEF_CLR		EQU INK_CYAN | PAPER_BLACK | CLR_BRIGHT
SCR_SEL_CLR		EQU INK_BLACK | PAPER_GREEN
SCR_LBL_CLR		EQU	SCR_SEL_CLR

;Special formating chars
CHR_CR			EQU	13
CHR_LF			EQU	10
CHR_TAB			EQU	09


;Semi-graphical chars
;           UC
;     UL +H-+--+UR
;        |  |  |
;     ML +--+--+MR
;        V C|  |
;     LL +--+--+LR
;           DC
CHR_GRID        EQU 127
CHR_V           EQU	128
CHR_MR          EQU	129
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
    ld a, HC_CFG_ROM_CPM
    out	(HC_CFG_PORT), a
	
	ld		hl, CPM_FNT
	ld		de, FontTable
	ld		bc, 872
	ldir
	
    ;restore BASIC ROM
    ld a, HC_CFG_ROM_BAS
    out	(HC_CFG_PORT), a
    ei
	
	ret
	ENDIF

ClrScr:
	ld		hl, (CurrScrAddr)
	ld		d, h
	ld		e, l
	inc		de
	ld		bc, SCR_PIX_LEN - 1
	ld		(hl), 0
	ldir

	inc 	hl
	inc		de

	ld		bc, SCR_ATTR_LEN - 1
	ld		(hl), SCR_DEF_CLR
	ldir

	;also set border color
	ld		a, SCR_DEF_CLR >> 3
	out		(PORT_ZX), a

	ld		a, SCR_DEF_CLR
	ld		(23624), a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;IN: HL = str. addr, DE = line/col, str ends with last char bit 7 set
PrintStr:
	ld		a, (hl)
	cp		' '
	jr		nc, GoodChar
	ld		a, '?'
GoodChar:
	bit		7, a
	res		7, a
	ld		(CODE), a
	ld		(LineCol), de
	ex		af, af'
	exx
	push	hl
	call 	PrintChar
	pop		hl
	exx
	ex		af, af'
	ret		nz

	inc		e
	inc		hl

	ld		a, e
	cp		64
	jr		c, PrintStr
	ld		e, 0
	inc		d

	jr		PrintStr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;IN: HL = string, DE = coords, A = color
PrintStrClr:
	ld		(StrClr), a
	push	de
		call	PrintStr
	pop		hl
	;get string len.
	ld		a, e
	sub		l
	rra
	ex		af, af'
		;line * 32
		ld		a, h
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

		ld		h, 0
		add		hl, de
		ld		de, (CurrScrAttrAddr)
		add		hl, de
	ex		af, af'
	ld		c, a
	ld		b, 0
	ld		d, h
	ld		e, l
	inc 	de
StrClr	EQU	$ + 1
	ld		(hl), INK_BLACK | PAPER_CYAN
	ldir
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;IN: B = length, D = line, E = col, A = char, C = horiz/vertical
DrawLine:
	ld		(CODE), a

	jr		c, VertDir
	ld		a, $1C
	jr		StoreDir
VertDir:
	ld		a, $14
StoreDir:
	ld		(LineDir), a

DrawLineLoop:
	ld		(LineCol), de
	push	de
		exx
		push	hl
		call 	PrintChar
		pop		hl
		exx
	pop		de
LineDir:
	inc		e
	djnz	DrawLineLoop

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawHLines:	
	ld		de, 0
	ld		b, 64
	ld		a, CHR_H
	or		a	
	call	DrawLine
	
	ld		de, LST_LAST_LINE << 8
	ld		b, 64
	ld		a, CHR_H
	or		a	
	call	DrawLine	
	
	ld		b, 4
	ld		de, LST_FIRST_COL
DrawUpperIntersectLoop:	
	push	bc
	push	de
		ld		a, CHR_UC
		call	DrawIntersect
	pop		de
	pop		bc
	ld		hl, NAMELEN+1
	add		hl, de
	ex		de, hl
	djnz	DrawUpperIntersectLoop
	
	ld		b, 4
	ld		de, (LST_LAST_LINE << 8) | LST_FIRST_COL
DrawLowerIntersectLoop:	
	push	bc
	push	de
		ld		a, CHR_DC
		call	DrawIntersect
	pop		de
	pop		bc
	ld		hl, NAMELEN+1
	add		hl, de
	ex		de, hl
	djnz	DrawLowerIntersectLoop
				
	ret	


DrawIntersect:
	ld		hl, LineCol
	ld		(hl), de	
	ld		(CODE), a
	push	hl
	call	PrintChar
	pop		hl
	inc		(hl)
	ld		a, CHR_H
	ld		(CODE), a
	call	PrintChar
	ret


DrawVLines:
	ld		b, 4
	ld		de, (LST_FIRST_LINE << 8) | LST_FIRST_COL
DrawVLinesLoop:
	push 	bc
	push	de
		ld		b, LST_LINES_CNT
		ld		a, CHR_V
		scf
		call	DrawLine
	pop		de
	pop	bc
	ld		a, e
	add		NAMELEN+1
	ld		e, a
	djnz	DrawVLinesLoop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;IN: A = color mask
DrawCursor:
	ld	de, (CursorAddr)
	ld	b, 	(NAMELEN + 1)/2
DrawCursorLoop:
	ld	(de), a
	inc de
	djnz DrawCursorLoop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;IN:	A = file idx.
MoveCursor:
	;File idx / SCR_LINES => cursor line & column
	ld		l, a
	ld		h, 0
	ld		c, LST_LINES_CNT
	call	Div					;HL = file column, A = line

	;cursor addr = SCR_ATTR_ADDR + (line + LST_FIRST_LINE) * SCR_BYTES_PER_LINE + column * NAMELEN/2
	add		LST_FIRST_LINE


	ld d, h
	ld e, l
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
	push	hl					;save line * 32
		ld		a, (NAMELEN + 1)/2
		call	Mul				;HL = column * 12/2
	pop		de
	add		hl, de

	ld		de, LST_FIRST_COL/2
	ld		bc, (CurrScrAttrAddr)
	add		hl, de
	add		hl, bc

	;clear old cursor
	ld		a, SCR_DEF_CLR
	call	DrawCursor

	;draw new one
	ld		(CursorAddr), hl
	ld		a, SCR_SEL_CLR
	call	DrawCursor

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PrintChar:
    ld		de, (LineCol)

    ;calculate 64 column screen address
	;IN: D = line, E = col
	;OUT: HL = screen address

    SRL     E                                       ;col = col/2
    RR      C                                       ;mark odd/even column
    LD      A, D                            ;A = line
    AND 24                                  ;keep only %00011000
    ld		hl, (CurrScrAddr)
    OR      h								;add screen start address
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
	ld		hl, FileData
	push	de
	pop		ix
	
ReadStringLoop:
	push	de
	push	hl
		call ReadChar
	pop		hl
	pop		de
	
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
	cp  127
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
	ld		hl, FileData
	push	ix
	pop		de
	call	PrintStr
	pop		de
	pop		hl	
		
	jr		ReadStringLoop
	
ClearNMsgLines:	
	ld		de, LST_LINE_MSG + 1 << 8
ClearNMsgLinesLoop:	
	push	de
	push	bc
	ld		hl, MsgClear
	ld		a, SCR_DEF_CLR
	call	PrintStrClr
	pop		bc
	pop		de
	inc		d
	djnz	ClearNMsgLinesLoop
	
	ret

CurrScrAddr		DEFW	SCR_ADDR
CurrScrAttrAddr	DEFW	SCR_ATTR_ADDR

   	endif