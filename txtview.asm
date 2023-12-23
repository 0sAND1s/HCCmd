	IFNDEF _TXTVIEW_
	DEFINE _TXTVIEW_

LINE_CNT	EQU	23
COL_CNT		EQU	64

CHAR_CR		EQU	$0D
CHAR_LF		EQU	$0A
CHAR_TAB	EQU	$09
CHAR_EOF	EQU	$1A

COORDS		EQU	23728		;Coordinates
SCRLinesDown	EQU PRN_BUF
SCRLinesUp		EQU	SCRLinesDown + LINE_CNT*2


	include "scroll.asm"
	include "math.asm"
	
TextViewer:	
	call	TextViewIndex
	
	ld		hl, 0
	ld		(COORDS), hl		
	call	ScrollInit	
	
TextViewerLoop2:	
	;Display 23 lines or less.
	ld		hl, (LineCount)
	ld		bc, LINE_CNT
	or		a
	sbc		hl, bc	
	ld		b, LINE_CNT
	jr		nc, MoreThan23LinesInFile
	ld		hl, (LineCount)
	ld		b, l
MoreThan23LinesInFile:	
	ld		ix, FileIdx

;Display first screen of text.
TextViewerLoop:	
	push	bc		
		call	PrintOneLine
		inc		ix
		inc		ix
		inc		ix
		
		ld		de, (COORDS)
		inc		d
		ld		e, 0
		ld		(COORDS), de	
	pop		bc	
	djnz	TextViewerLoop	
		
	ld		de, 0
	ld		(FirstLineShown), de
	
	dec		ix
	dec		ix
	dec		ix
	
	ld		hl, (LineCount)		
	ld		de, MsgLineTotal
	call	Word2Txt
	
TextViewerLoop3:			
	ld		hl, (FirstLineShown)		
	inc		hl	
	ld		de, MsgLineNo
	call	Word2Txt
	
	ld		hl, (SelFileCache)
	ld		de, MsgLineFileName
	ld		b, NAMELEN
TextViewerShowFilename:	
	ld		a, (hl)
	and		$7F
	ld		(de), a
	inc		hl
	inc		de
	djnz	TextViewerShowFilename

	ld		hl, MsgLine		
	ld		de, LINE_CNT << 8
	ld		a, SCR_SEL_CLR
	call	PrintStrClr
	
	call	ReadChar
	
	cp		KEY_DOWN
	jr		z, TextViewerScrollDown
	
	cp		KEY_UP
	jr		z, TextViewerScrollUp
	
	cp		'0'
	ret		z
	
	jr		TextViewerLoop3
	
TextViewerScrollUp:	
	;Do nothing if showing begining of file.
	ld		de, (FirstLineShown)
	ld		a, d
	or		e
	jr		z, TextViewerLoop3	
	
	dec		de
	ld		(FirstLineShown), de
	
	ld		a, d
	or		e
	ld		ix, FileIdx
	jr		z, TextViewerScrollUp1

	;3*FirstLineShown						
	ld		a, 3
	call	Mul	
	ex		de, hl	
	or		a
	add		ix, de
	

TextViewerScrollUp1:
	call	ScrollUp	
	ld		de, (COORDS)
	ld		de, 0	
	ld		(COORDS), de					
	call	PrintOneLine	
	
	jr		TextViewerLoop3
	
TextViewerScrollDown:	
	;Exit if reached last line from file.
	ld		hl, (FirstLineShown)		
	ld		bc, LINE_CNT+1
	or		a
	adc		hl, bc
	ex		de, hl
	ld		hl, (LineCount)
	or		a
	sbc		hl, de
	jr		c, TextViewerLoop3
	
	ld		hl, (FirstLineShown)
	inc		hl
	ld		(FirstLineShown), hl
	ld		bc, LINE_CNT-1
	or		a
	adc		hl, bc
	ex		de, hl

	;(FirstLineShown + 23	) * 3
	ld		a, 3
	call	Mul
	ex		de, hl
	ld		ix, FileIdx
	add		ix, de

	call	ScrollDown
	ld		de, (COORDS)
	ld		de, (LINE_CNT - 1) << 8	
	ld		(COORDS), de
				
	call	PrintOneLine
		
	jp		TextViewerLoop3	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;Creates line start indexes, with 2 byte address and 1 byte length for each line. Stores total line count.
;IN: HL=start address, BC: length
TextViewIndex:
	ld		ix, FileIdx
	
	;Search for CHAR_EOF, to mark end of buffer there, if found.
	;Save initial length in DE.	
	push	hl
		push	bc
			ld		a, CHAR_EOF
			cpir
			
			push	hl
			pop		de				;DE will contain the address of EOF char or end of file.
		pop		bc
	pop		hl			
	
	dec		de
	ld		(FileEnd), de
	
	ld		de, 0					;Assume at least one line is shown, even if empty.
	ld		(LineCount), de
	
TextViewIndexLoop:	
	ld		(ix), l	
	ld		(ix+1), h
	
	ld		bc, COL_CNT			;Search CR char, might be on position 65.
	ld		a, CHAR_CR
	cpir		
	
	ld		a, CHAR_CR			;Don't show an empty line if the CR char is exactly after 64 chars.
	cp		(hl)
	jr		nz, TextViewCheckLF
	inc		hl
				
TextViewCheckLF:				
	ld		a, CHR_LF
	cp		(hl)
	jr		nz, TextViewIndexNoLF	
	inc		hl						;Skip LF char.
	
TextViewIndexNoLF:
		
	;If line shorter than 64 chars, calculate actual length.
	ld		a, c	
	or		a						;if c==0, line was 64 chars
	ld		a, COL_CNT	
	jr		z, TextViewIndexStoreLineLen			
	inc		c						;account for the CR char found.
	sub		c		
	
TextViewIndexStoreLineLen:	
	ld		(ix+2), a	
	ld		de, (LineCount)
	inc		de
	ld		(LineCount), de
	
	;Check end of file.				
	ld		a, CHAR_EOF
	cp		(hl)		
	ret		z

TextViewerIncrementIndex:		
	;Point to the next index position.
	inc		ix
	inc		ix
	inc		ix			
		
TextViewerCheckEnd:	
	push	hl
		ex		de, hl
		ld		hl, (FileEnd)
		or		a
		sbc		hl, de		
	pop		hl
	jr		nc, TextViewIndexLoop

TextViewerEnd:	
	ret
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintOneLine:
	ld		l, (ix)	
	ld		h, (ix+1)
	ld		a, (ix+2)	
		
	or		a
	ld		b, COL_CNT
	jr		z, PrintOneLineCleanLine
	
	ld		b, a
PrintOneLineLoop:	
	ld		a, (hl)	
	
	;Put space instead of tab
	cp		CHAR_TAB
	jr		nz, PrintOneLineNotTab
	ld		a, ' '
	
PrintOneLineNotTab:	
	push	hl
		cp	' '
		jr	c, PrintCharNotValid
		cp  127
		jr	nc, PrintCharNotValid
		
		jr	PrintCharValid	
PrintCharNotValid:	
		ld	a, '.'
PrintCharValid:
		ld		(CODE), a
		push	bc			
			call	PrintChar			
		pop		bc

		ld		de, (COORDS)
		inc		e
		ld		(COORDS), de
	pop		hl
	inc		hl
	djnz	PrintOneLineLoop
		
	;Fill rest of line with spaces.
	ld		b, (ix+2)
	ld		a, COL_CNT
	cp		b
	ret		z
	
	or		a
	sbc		b
	ld		b, a		
		
PrintOneLineCleanLine:		
	ld		a, ' '
	ld		(CODE), a
	push	bc			
		call	PrintChar	
		ld		de, (COORDS)
		inc		e
		ld		(COORDS), de		
	pop		bc
	djnz	PrintOneLineCleanLine
	
	ret	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FileEnd			DEFW	0
LineCount		DEFW	0
FirstLineShown	DEFW	0
	
MsgLine			defb	'File: '
MsgLineFileName defb 	'           |'
				defb	'Line: '
MsgLineNo		defb	'     /'
MsgLineTotal	defb	'     |'
				defs	21, ' '
				defb	'|0:Exi', 't' | $80
	
	ENDIF