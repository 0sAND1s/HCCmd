; 	DEVICE ZXSPECTRUM48

LINE_CNT	EQU	23
COL_CNT		EQU	64

CHAR_CR		EQU	$0D
CHAR_LF		EQU	$0A
CHAR_TAB	EQU	$09
CHAR_EOF	EQU	$1A

COORDS		EQU	23728		;Coordinates


InitViewer:
	ld		 (FileBegin), hl
	add		hl, bc
	;must filter any EOF chars.	
	ld		a, CHAR_EOF
	dec		h		
	dec		h			
	ld		bc, SECT_SZ	* 4
	cpir
	dec		hl	
	ld		(FileEnd), hl
	ld		de, (FileBegin)
	or		a
	sbc		hl, de
	ld		(FileLen), hl

	ld		a, CHAR_CR
	ld		(hl), a


	ld		hl, (2 << 8) | 4
	ld		(REPDEL), hl

	ld		hl, 0
	ld		(COORDS), hl

	ld		hl, SCR_ADDR + SCR_PIX_LEN
	ld		d, h
	ld		e, l
	inc		de
	ld		bc, 767
	ld		(hl), SCR_DEF_CLR
	ldir

	call	ScrollInit

	ld		de, 0
	ld		(CurLine), de

	;prepare file progress %
	ld		hl, (FileLen)
	ld		a, h
	ld		c, l
	ld		de, 100
	call	Div2
	ld		h, a
	ld		l, c
	ld		(PROGR_PERC), hl

	call	PrintMsg

	ld		ix, FileIdx	- 2
	ld		b, LINE_CNT
	ld		hl, (FileBegin)

	ret
	

PrintLoop:
	push	bc
		inc		ix
		inc		ix
		ld		(ix), l
		ld		(ix + 1), h

		call	GetLine
		call	PrintLine

		ld		de, (CurLine)
		inc		de
		ld		(CurLine), de
	pop		bc
	call	CheckEnd
	jr		c, ViewFileEOF

	djnz	PrintLoop
	jr		PrintLoop2

GetKey:
	halt
	bit		5, (iy + 1);
	jr		z, GetKey
	res		5, (iy + 1)
	ld		a, (iy - $32)
	ret

ViewFileEOF:
	call	GetKey
	cp		'0'
	jr		nz, ViewFileEOF
	ret

PrintLoop2:
	call	PrintMsg

	call	GetKey
	cp		'0'					;Exit on 0
	ret		z

	cp		KEY_DOWN
	jr		z, Down

	cp		KEY_UP
	jr		z, Up

	cp		'2'
	jr		nz, PrintLoop2

	ld		a, (WrapFlag)
	xor		1
	ld		(WrapFlag), a
	or		a
	jr		z, NoWrap

	ld		de, 'nO'
	ld		(MsgLineWrF), de
	ld		a, ' '
	ld		(MsgLineWrF + 2), a
	jp		PrintLoop2

NoWrap:
	ld		de, 'fO'
	ld		(MsgLineWrF), de
	ld		a, 'f'
	ld		(MsgLineWrF + 2), a

	jp		PrintLoop2


Up:
	call	CheckBegin
	jr		z, PrintLoop2

	call	ScrollUp

	dec		ix
	dec		ix
	ld		l, (ix - (LINE_CNT-1)*2)
	ld		h, (ix - (LINE_CNT-1)*2 + 1)
	call	GetLine						;extract previous line to display

	ld		de, 0
	ld		(COORDS), de
	call	PrintLine

	ld		hl, (CurLine)
	dec		hl
	ld		(CurLine), hl
	call	PrintMsg
	jr		PrintLoop2


Down:
	ld		l, (ix)
	ld		h, (ix + 1)
	call	GetLine						;get next line pointer

	call	CheckEnd					;check if HL == file end
	ret		c

	inc		ix								;save next line pointer
	inc		ix
	ld		(ix), l
	ld		(ix + 1), h

	call	GetLine						;extract next line in buffer for display

	call	ScrollDown

	ld		de, (LINE_CNT-1) << 8
	ld		(COORDS), de
	call	PrintLine

	ld		hl, (CurLine)
	inc		hl
	ld		(CurLine), hl
	call	PrintMsg

	jp		PrintLoop2


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;check begining of buffer
CheckBegin:
	push	hl
		ld		l, (ix - (LINE_CNT-1) * 2)
		ld		h, (ix - (LINE_CNT-1) * 2 + 1)
		ld		de, (FileBegin)
		or		a
		sbc		hl, de
	pop		hl
	ret

;check end of buffer
CheckEnd:
	push	hl
		ld		de, (FileEnd)
		ex		de, hl
		or		a
		sbc		hl, de
	pop		hl
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Print a line
PrintLine:
	ld		de, LineBuf
	ld		b, COL_CNT

	call	PrintStrTxt

	;go to the next screen line
	ld		de, (COORDS)
	inc		d
	ld		e, 0
	ld		(COORDS), de
	ret

PrintStrTxt:
	ld		a, (de)
	inc		de
	push	de
		ld		(CODE), a
		push	bc
			push	hl
				call	PrintChar
			pop		hl
		pop		bc

		ld		de, (COORDS)
		inc		e
		ld		(COORDS), de
	pop		de
	djnz	PrintStrTxt
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Extract a line of text to fit exactly on a 64 screen line
;IN:	HL = current file pointer
;OUT:	LineBuf = new line for display, HL = pointer to the next line
GetLine:
	ld		de, LineBuf
	ld		b, COL_CNT
GetLineLoop:
	ld		a, (hl)
	inc		hl

	cp		CHAR_CR
	jr		z, GetLineSkip0A

	cp		CHAR_LF
	jr		z, GetLineSkip0A

	cp		CHAR_TAB
	jr		z, GetLineTab	
	
	cp		CHAR_EOF
	jr		z, GetLineFillLoop
	
	jr		GetLineNext

GetLineTab:
	;1 space tab
	ld		a, ' '
	ld		(de), a
	inc		de	
	dec		b
	jr		z, GetLineSkip0D	;skip tab on end of line

GetLineNext:
	cp		' '
	jr		c, NotValid

	cp		128
	jr		nc, NotValid
	jr		Valid

NotValid:
	call	ReplaceChars

Valid:
	ld		(de), a
	inc		de
	djnz	GetLineLoop

;if line is exactly 64 char long, must skip the new line char(s)
GetLineSkip0D:
	ld		c, 0
	ld		a, CHAR_CR						;skip 0D
	cp		(hl)
	jr		nz, GetLineSkip0A
	inc		hl
	inc		c

GetLineSkip0A:						;skip 0A
	ld		a, CHAR_LF
	cp		(hl)
	jr		nz, GetLineFill
	inc		hl
	inc		c
	
GetLineFill:
	ld		a, b
	or		a
	jr		nz, GetLineFillLoop

	ld		a, c
	or		a
	ret		nz

	;wrap or not
	ld		a, (WrapFlag)
	or		a
	ret		nz

	/*
	ld		de, (FileEnd)
	push	hl
		ex		de, hl
		or		a
		sbc		hl, de
		ld		b, h
		ld		c, l				
	pop		hl
	*/
	
	ld		a, CHAR_CR
	ld		bc, COL_CNT
	cpir
	ret		nz
	ld		a, CHAR_LF
	cp		(hl)
	ret		nz
	inc		hl

	ret

GetLineFillLoop:				;fill the rest of the displayed line with blanks
	ld		a, ' '
	ld		(de), a
	inc		de
	djnz	GetLineFillLoop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintMsg:
	ld		de, (COORDS)
	push	de
	ld		de, LINE_CNT<<8
	ld		(COORDS), de

	;Get current file pointer
	ld		l, (ix)
	ld		h, (ix + 1)
	ld		bc, (FileBegin)
	or		a
	sbc		hl, bc

	;Divide by one percent length
	ld		a, h
	ld		c, l
	ld		de, (PROGR_PERC)
	call	Div2

	;Display %
	ld		de, MsgLinePr
	ld		h, a
	ld		l, c
	call	Byte2Txt


	ld		hl, (CurLine)
	ld		de, MsgLineNo
	call	Word2Txt

	ld		de, MsgLine
	ld		b, MsgLineLen
	call	PrintStrTxt
	pop		de
	ld		(COORDS), DE

	ld		hl, SCR_ADDR + SCR_PIX_LEN + LINE_CNT*32
	ld		d, h
	ld		e, l
	inc		de
	ld		a, SCR_LBL_CLR
	ld		(hl), a
	ld		bc, SCR_BYTES_PER_LINE-1
	ldir
	ret


ReplaceChars:
	push	hl
	push	bc
		ld		hl, CharReplaceTbl
		ld		b, CharReplTblLen
ReplaceSGCLoop:
		cp		(hl)
		jr		z, ReplaceMatch
		inc		hl
		inc		hl
		djnz	ReplaceSGCLoop

		ld		a, '?'
		pop		bc
		pop		hl
	ret

ReplaceMatch:
		inc		hl
		ld		a, (hl)
	pop		bc
	pop		hl
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	include	"scroll.asm"

CharReplaceTbl:
	defb	179, 128
	defb	180, 129
	defb	191, 130
	defb	192, 131
	defb	193, 132
	defb	194, 133
	defb	195, 134
	defb	196, 135
	defb	197, 136
	defb	217, 137
	defb	218, 138
	defb	219, 139
	defb	220, 140
CharReplTblLen EQU	($ - CharReplaceTbl)/2

MsgLine		defb	'Progress:'
MsgLinePr	defb	'   %; '
			defb	'Line: '
MsgLineNo	defb	'     ; '
MsgLineWrap	defb	'2-Wrap '
MsgLineWrF	defb	' On'
			defb	'; 0-Exit'
MsgLineLen	EQU		$ - MsgLine

LineBuf		defb	'                                                                '
CurLine		defw	0
WrapFlag	defb	1
FileBegin	defw	0
FileLen		defw	0
FileEnd		defw	0
PROGR_PERC	defw	0

SCRLinesDown	EQU PRN_BUF
SCRLinesUp		EQU	SCRLinesDown + LINE_CNT*2
End:
