	IFNDEF _TXTVIEW_
	DEFINE _TXTVIEW_

LINE_CNT	EQU	23
COL_CNT		EQU	64

CHAR_CR	EQU	$0D
CHAR_LF	EQU	$0A
CHAR_TAB	EQU	$09
CHAR_EOF	EQU	$1A

COORDS		EQU	23728	;Coordinates
SCRLinesDown	EQU	PRN_BUF
SCRLinesUp	EQU	SCRLinesDown + LINE_CNT*2


	include "scroll.asm"
	include "math.asm"
	
TextViewer:	
	call	TextViewIndex
	
	ld	hl, 0
	ld	(COORDS), hl			
	call	ScrollInit	
		
	;Check if we have in file 23 lines or less.
	ld	hl, (LineCount)
	ld	bc, LINE_CNT
	or	a
	sbc	hl, bc	
	ld	b, LINE_CNT
	jr	nc, MoreThan23LinesInFile
	
	;If file has less than 23 lines, show only lines 0 to line count-1.
	ld	hl, (LineCount)
	ld	b, l
	dec	hl
	ld	de, 0
	jr	TextViewerShowBegining
	
MoreThan23LinesInFile:	
	;Check last key pressed to see if we need to show last part of file or the first part.
	ld	a, (LAST_K)
	cp	KEY_UP
	ld	de, 0
	ld	hl, LINE_CNT-1
	jr	nz, TextViewerShowBegining	
	
	;Must show end of file.
	ld	hl, (LineCount)
	dec	hl
	push	hl
	push	bc
		ld	bc, LINE_CNT-1
		or	a
		sbc	hl, bc
		ld	d, h
		ld	e, l
	pop	bc
	pop	hl
	
TextViewerShowBegining:	
	ld	(LastLineShown), hl
	ld	(FirstLineShown), de
	
	;If first line is 0, don't need to add offset.
	ld	a, d
	or	e
	ld	ix, FileIdx
	jr	z, TextViewerLoop
	
	;Get pointer to the first line index.
	ld	a, 3
	push	bc
	push	hl
		call	Mul
		ld	b, h
		ld	c, l
		add	ix, bc
	pop	hl
	pop	bc		

;Display first screen of text.
TextViewerLoop:	
	push	bc		
		call	PrintOneLine
		inc	ix
		inc	ix
		inc	ix
		
		ld	de, (COORDS)
		inc	d
		ld	e, 0
		ld	(COORDS), de	
	pop	bc	
	djnz	TextViewerLoop	
			
	dec	ix
	dec	ix
	dec	ix
	
	ld	hl, (LineCount)		
	ld	de, MsgLineTotal
	call	Word2Txt
	
TextViewerLoop3:		
	ld	hl, (LastLineShown)	
	inc	hl
	ld	de, MsgLineNo
	call	Word2Txt
	ld	a, (ViewFilePart)
	inc	a
	ld	l, a
	ld	h, 0
	ld	de, MsgFilePart
	call	Byte2Txt
	
	ld	hl, (SelFileCache)
	ld	de, MsgLineFileName
	ld	b, NAMELEN
TextViewerShowFilename:	
	ld	a, (hl)
	and	$7F
	ld	(de), a
	inc	hl
	inc	de
	djnz	TextViewerShowFilename

	ld	hl, MsgLine		
	ld	de, LINE_CNT << 8
	ld	a, SCR_SEL_CLR
	call	PrintStrClr
	
	call	ReadChar
	
	cp	KEY_DOWN
	jr	z, TextViewerScrollDown
	cp	'a'
	jr	z, TextViewerScrollDown
	
	cp	KEY_UP
	jr	z, TextViewerScrollUp
	cp	'q'
	jr	z, TextViewerScrollUp
	
	cp	'0'
	ret	z
	
	jr	TextViewerLoop3
	
TextViewerScrollUp:	
	;Do nothing if showing begining of file.
	ld	de, (FirstLineShown)
	ld	a, d
	or	e
	jr	nz, TextViewerScrollUpOK
	
	ld	a, (ViewFilePart)
	or	a
	jr	z, TextViewerLoop3
	ret
	
TextViewerScrollUpOK:	
	dec	de
	ld	(FirstLineShown), de
	
	ld	hl, (LastLineShown)
	dec	hl
	ld	(LastLineShown), hl
	
	ld	a, d
	or	e
	ld	ix, FileIdx
	jr	z, TextViewerScrollUp1

	;3*FirstLineShown					
	ld	a, 3
	call	Mul	
	ex	de, hl	
	or	a
	add	ix, de
	

TextViewerScrollUp1:
	call	ScrollUp	
	ld	de, (COORDS)
	ld	de, 0	
	ld	(COORDS), de
	call	PrintOneLine	
	
	jp	TextViewerLoop3
	
TextViewerScrollDown:	
	;Exit if reached last line from file and more data is available for reading.
	ld	de, (LastLineShown)
	inc	de
	ld	hl, (LineCount)
	or	a
	sbc	hl, de
	ld	a, h
	or	l
	jr	nz, TextViewerScrollDown1
	
	;Exit if not end of file.
	ld	a, (CopyFileRes)
	or	a
	jp	nz, TextViewerLoop3
	ret
	
TextViewerScrollDown1:
	ld	(LastLineShown), de
	
	ld	hl, (FirstLineShown)
	inc	hl
	ld	(FirstLineShown), hl		

	;Index of next line = LastLineShown * 3
	ld	a, 3
	call	Mul
	ex	de, hl
	ld	ix, FileIdx
	add	ix, de

	call	ScrollDown
	ld	de, (COORDS)
	ld	de, (LINE_CNT - 1) << 8	
	ld	(COORDS), de
			
	call	PrintOneLine		
	jp	TextViewerLoop3	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;Creates line start indexes, with 2 byte address and 1 byte length for each line. Stores total line count.
;IN: HL=start address, BC: length
TextViewIndex:
	ld	ix, FileIdx
	
	;Save initial length in DE.	
	push	hl
		or	a
		adc	hl, bc
		ex	de, hl
	pop	hl		
	
	ld	(FileEnd), de
	
	ld	de, 0				;Assume at least one line is shown, even if empty.
	ld	(LineCount), de
	
TextViewIndexLoop:	
	ld	(ix), l	
	ld	(ix+1), h
	
	;BC to hold 64 or less, if on last line from file.
	ld	de, (FileEnd)
	ex	de, hl
	or	a
	sbc	hl, de	
	ret	z
	
	push	hl
		ld	bc, COL_CNT
		or	a
		sbc	hl, bc
		ex	de, hl
	pop	de
	ld	a, c
	jr	nc, TextViewLineShort
	ld	a, e
	
TextViewLineShort:			
	ld	e, a		;Save line lenght.
	
	;Must detect if line is shorter because of CR.
	ld	c, a
	ld	a, CHAR_CR
	cpir
	jr	nz, TextViewNotFoundCR
	inc	c
	
TextViewNotFoundCR:	
	ld	a, e
	sub	c	
	ld	(ix+2), a	
		
	ld	a, CHAR_CR	;Don't show an empty line if the CR char is exactly after 64 chars.
	cp	(hl)
	jr	nz, TextViewCheckLF
	inc	hl
				
TextViewCheckLF:				
	ld	a, CHR_LF
	cp	(hl)
	jr	nz, TextViewNoLF
	inc	hl					;Skip LF char.
TextViewNoLF:
		
	;Point to the next index position.
	ld	bc, (LineCount)
	inc	bc
	ld	(LineCount), bc
	
	inc	ix
	inc	ix
	inc	ix	
	jr	 TextViewIndexLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintOneLine:
	ld	l, (ix)	
	ld	h, (ix+1)
	ld	a, (ix+2)	
		
	or	a
	ld	b, COL_CNT
	jr	z, PrintOneLineCleanLine
	
	ld	b, a
PrintOneLineLoop:	
	ld	a, (hl)	
	
	;Put space instead of tab
	cp	CHAR_TAB
	jr	nz, PrintOneLineNotTab
	ld	a, ' '
	
PrintOneLineNotTab:	
	push	hl
		cp	' '
		jr	c, PrintCharNotValid
		cp	CHR_HALF
		jr	nc, PrintCharNotValid
		
		jr	PrintCharValid	
PrintCharNotValid:	
		ld	a, '.'
PrintCharValid:
		ld	(CODE), a
		push	bc		
			call	PrintChar		
		pop	bc

		ld	de, (COORDS)
		inc	e
		ld	(COORDS), de
	pop	hl
	inc	hl
	djnz	PrintOneLineLoop
		
	;Fill rest of line with spaces.
	ld	b, (ix+2)
	ld	a, COL_CNT
	cp	b
	ret	z
	
	or	a
	sbc	b
	ld	b, a		
		
PrintOneLineCleanLine:		
	ld	a, ' '
	ld	(CODE), a
	push	bc		
		call	PrintChar	
		ld	de, (COORDS)
		inc	e
		ld	(COORDS), de		
	pop	bc
	djnz	PrintOneLineCleanLine
	
	ret	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FileEnd		DEFW	0
LineCount	DEFW	0
FirstLineShown	DEFW	0
LastLineShown	DEFW	0
	
MsgLine	defb	'File:'
MsgLineFileName defb 	'           |'
		defb	'Line:'
MsgLineNo	defb	'     /'
MsgLineTotal	defb	'     |'
		defb	'Segment:'
MsgFilePart	defb	'   |'
		defs	10, ' '
		defb	'|0:Exi', 't' | $80
	
	ENDIF