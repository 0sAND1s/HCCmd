	ifndef	_MATH_
	define	_MATH_

;The folowing 4 routines where inspired/adapted from: Milos "baze" Bazelides, baze@stonline.sk
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
;IN: HL=address to read, DE=output address for 2 chars
BytePtr2Hex:	
	IFUSED
	xor	a
	rld
	call	BytePtr2HexNibble

BytePtr2HexNibble:
	push	af
	daa
	add	a,$F0
	adc	a,$40

	ld	(de), a	
	inc	de

	pop	af
	rld
	ret		
	ENDIF

;Converts A into text hex number in DE
ByteToHex:   
	ld	c, a   ; a = number to convert
	call	ByteToHex1
	ld	d, a
	ld	a, c
	call	ByteToHex2
	ld	e, a
	ret  ; return with hex number in de

ByteToHex1:    
	rra
	rra
	rra
	rra
ByteToHex2:    
	or	$F0
	daa
	add	a, $A0
	adc	a, $40 ; Ascii hex at this point (0 to F)   
	ret


;Number in HL converted is converted to 4 byte hex chars in DE:HL.
Word2Hex:
	ld	a, h
	call	ByteToHex
	ld	a, l
	ex	de, hl
	call	ByteToHex	
	ret
	
	
;Convert 2 digit hex number from DE to A.	
HexToNum:
	IFUSED
	ld   a,d
	call Hex1
	add  a,a
	add  a,a
	add  a,a
	add  a,a
	ld   d,a
	ld   a,e
	call Hex1
	or   d
	ret

Hex1:    
	sub  a,'0'
	cp   10
	ret  c
	sub  a,'A'-'0'-10
	ret	
	ENDIF

	endif