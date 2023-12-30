	ifndef	_MATH_
	define	_MATH_

;The folowing 3 routines where inspired or taken from: Milos "baze" Bazelides, baze@stonline.sk
;http://map.tni.nl/sources/external/z80bits.html


Word2Txt:
	IFUSED
	push	de
		call	Word2Txt_
	pop	de

	ld	b, 4
	call	StrippLeading0
	ret

Byte2Txt:
	push	de
		call	Byte2Txt_
	pop	de

	ld	b, 2
	call	StrippLeading0
	ret
	ENDIF


StrippLeading0:
	ld	a, (de)
	cp	'1'
	ret	nc

	ld	a, ' '
	ld	(de), a
	inc	de
	djnz	StrippLeading0
	ret


;Converts the number in HL to ASCII in decimal string at DE
Word2Txt_:
	ld bc, -10000
	call DigitLoop
	ld bc, -1000
	call DigitLoop
Byte2Txt_:
	ld bc, -100
	call DigitLoop
	ld bc, -10
	call DigitLoop
	ld bc, -1

DigitLoop:
	ld	a, '0' - 1
DivNrLoop:
	inc	a		;increase reminder
	add	hl, bc	;substract divizor
	jr	c, DivNrLoop	;still dividing?
	sbc	hl, bc	;nope, restore

	ld (de), a
	inc de
	ret


;Input: HL = Dividend, C = Divisor
;Output: HL = Quotient, A = Remainder
;Warning: doesn't work with divisor >= $80
Div:
	IFUSED
	xor a
	ld b, 16

DivLoop:
	add	hl,hl
	rla
	cp	c
	jr	c, NoSub
	sub	c
	inc	l
NoSub:
	djnz DivLoop

	ret
	ENDIF

;Input: A:C = Dividend, DE = Divisor, HL = 0
;Output: A:C = Quotient, HL = Remainder
Div2:
	ld hl, 0
	ld b, 16
Div2Loop:
	sll c	; unroll 16 times
	rla		; ...
	adc	hl,hl	; ...
	sbc	hl,de	; ...
	jr	nc,$+4	; ...
	add	hl,de	; ...
	dec	c	; ...
	djnz Div2Loop
	ret


;Input: A = Multiplier, DE = Multiplicand
;Output: A:HL = Product
Mul:
	IFUSED
	ld hl, 0
	ld bc, $0700

	add	a, a	; optimised 1st iteration
	jr	nc, MulLoop
	ld	h, d
	ld	l, e

MulLoop:
	add	hl,hl
	rla
	jr	nc, NoAdd
	add	hl,de
	adc	a,c
NoAdd:
	djnz MulLoop

	ret
	ENDIF
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;IN: HL=address to read, DE=output address	for 2 chars
Byte2Hex:	
	xor	a
	rld
	call	Byte2HexNibble

Byte2HexNibble:
	push	af
	daa
	add	a,$F0
	adc	a,$40

	ld	(de), a	
	inc	de

	pop	af
	rld
	ret	
		

Byte2HexHex:	
	call	Byte2Hex			
	inc	hl
	ld	a, ' '
	ld	(de), a
	inc	de	
	ret
		
Byte2HexChar:	
	ld	a, CHAR_CR
	cp	(hl)
	jr	nz, Bin2HexLineLoopTextCopy
	
Bin2HexLineLoopTextReplace:	
	ld	a, '.'
	ld	(hl), a
	
Bin2HexLineLoopTextCopy:	
	ldi
	ret


HEX_COLUMNS	EQU	16

Bin2HexLine:		
	;Hex part	
	ld	b, HEX_COLUMNS
	push	hl
Bin2HexLineLoopHex:
		call	Byte2HexHex
		djnz	Bin2HexLineLoopHex	
	pop	hl
	
	dec	de
	ld	a, CHR_V
	ld	(de), a
	inc	de
	
	ld	ixh, d
	ld	ixl, e
	ld	(ix - (HEX_COLUMNS/2)*3 - 1), a
	
	;String part
Bin2HexLineText:	
	;just to not alter B with LDI, set C to something > 16
	ld	bc, (HEX_COLUMNS << 8) | HEX_COLUMNS*2
Bin2HexLineLoopText:
	call	Byte2HexChar
	djnz	Bin2HexLineLoopText
	ret
		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Converts binary buffer at HL to hex string at DE
Bin2HexStr:		
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
	
	ex		af, af'		;Keep reminder
	
Bin2HexStrLoop:	
	push	bc		
		call	Bin2HexLine
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
	ex	af, af'
	
	;Clear the whole last line.
	push	de
	push	hl
		ld	a, ' '		
		ld	b, COL_CNT
Bin2HexLineClear:		
		ld	(de), a
		inc	de
		djnz	Bin2HexLineClear			
	pop	hl
	pop	de	
	
	;Save start of last line.
	push	de
	pop	ix
	push	ix
	
	;Save start of char part in IX.
	ld	bc, HEX_COLUMNS*3
	add	ix, bc	
	
	;Write the hex and char parts of line.
	ex	af, af'
	ld	b, a	
	ld	c, HEX_COLUMNS*2

Bin2HexLineLoopHex2:
	call	Byte2HexHex
	dec	hl
	
	push	de
		ld	e, ixl
		ld	d, ixh
		ld	c, 1
		call	Byte2HexChar
	pop	de
	
	inc	ix
	djnz	Bin2HexLineLoopHex2	
	
	;Save end of buffer in DE, to let the caller know where the buffer ends.
	ld	e, ixl
	ld	d, ixh
	
	pop	ix
	;Write delimiters.
	ld	a, CHR_V
	ld	(ix + HEX_COLUMNS*3/2 - 1), a
	ld	(ix + HEX_COLUMNS*3 - 1), a
		
	ret		

	endif