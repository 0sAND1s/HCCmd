;Scrolling routines for UP/DOWN
;They use 2 tables of pointers of screen cell rows.
;One table has addresses in increasing order, for scroll down,
;the other in decreasing order, for scroll up, so the same
;scroll routine is used in both cases.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Char Down
; Adjusts screen address HL to move eight pixels down on the display.
; enter: HL = valid screen address
; exit : HL = moves one character down
; used : AF, HL
GetCellDown:
	ld a,l
	add a,$20
	ld l,a
	ret nc
	ld a,h
	add a,$08
	ld h,a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Fills the two tables with pointers.
ScrollInit:
	ld		hl, 16384
	ld		b, LINE_CNT
FillScrLinesLoop:
FillScrLinesPtr	EQU	$ + 1			;pointer in table
	ld		(SCRLinesDown), hl
	;inc. pointer in destination table (of pointers to lines)
	ld		de, (FillScrLinesPtr)
	inc		de
	inc		de
	ld		(FillScrLinesPtr), de
	call	GetCellDown
	djnz	FillScrLinesLoop

	;now fill the table in reverse
	ld		(FillScrLinesSPStore), sp
	ld		sp, SCRLinesUp + LINE_CNT*2
	ld		b, LINE_CNT
	ld		hl, SCRLinesDown
FillScrLinesRev:
	ld		e, (hl)
	inc		hl
	ld		d, (hl)
	inc		hl
	push	de
	djnz	FillScrLinesRev
FillScrLinesSPStore	EQU	$ + 1
	ld		sp, 0
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ScrollUp:
	ld		hl, SCRLinesUp
	jr		Scroll

ScrollDown:
	ld		hl, SCRLinesDown

Scroll:
	ld		(ScrollDownPtrDest), hl
	inc		hl
	inc		hl
	ld		(ScrollDownPtrSrc), hl
	ld		c, LINE_CNT - 1

ScrollDownLoop2:
	ld		b, 4
ScrollDownPtrDest	EQU	$ + 2
	ld		de, (SCRLinesDown)
ScrollDownPtrSrc	EQU	$ + 1
	ld		hl, (SCRLinesDown + 2)

ScrollDownLoop:					;copy a single char line
	push	bc
	ld		bc, 32
	ldir
	dec		hl
	dec		de
	inc		h
	inc		d
	ld		bc, 32
	lddr
	inc		hl
	inc		de
	inc		h
	inc		d
	pop		bc
	djnz	ScrollDownLoop

	dec		c
	ret		z

	ld		hl, (ScrollDownPtrSrc)
	ld		(ScrollDownPtrDest), hl
	inc		hl
	inc		hl
	ld		(ScrollDownPtrSrc), hl
	jr		ScrollDownLoop2