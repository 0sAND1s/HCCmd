	IFNDEF _BAS2TXT_
	DEFINE _BAS2TXT_

CHANS		EQU		23631
CH_LEN		EQU		5
CHANNEL		EQU		3
CHAN_OPEN	EQU		$1601

NumMarker	EQU		$0E

PO_SEARCH	EQU		$0C41
TKN_TABLE	EQU		$0095
	
	
;Input: HL=source of program, BC=length of program, DE=text output address
;Output: DE=end of text
BASIC2TXT:
	ld		(ProgramStartAddr), hl		
	add		hl, bc
	ld		(ProgramEndAddr), hl
	ld		(DestinationAddr), de	

	;Open channel.
	LD   A, CHANNEL
	CALL CHAN_OPEN		;

	;modify output routine
	ld   hl, (CHANS)
	ld	 bc, CH_LEN * CHANNEL
	add	 hl, bc
	ld   de, OutputFnct
	ld   (hl), e
	inc	hl
	ld	(hl), d
	
	ld	hl, (ProgramStartAddr)	

NextLine:	
	PUSH HL	
		or	 a
		ld   de, (ProgramEndAddr)
		ex	de, hl
		SBC  HL,DE
		LD   A,H
		OR   L
	POP  HL
	RET  Z				;Return if length == 0.

	;Print line number
	ld		a, ' '
	call	PrintIt
	LD   B,(HL)
	INC  HL
	LD   C,(HL)
	INC  HL
	PUSH HL
		CALL $2D2B		;STACK_BC
		CALL $2DE3		;PRINT_FP
		ld		a, ' '
		call	PrintIt
	POP  HL

	;Get line length in BC.
	LD   C,(HL)
	INC  HL
	LD   B,(HL)
	INC  HL

	;Save line end address.
	PUSH HL
		ADD  HL,BC
		LD   (LineEndAddr),HL
	POP  HL

GetCharLoop:
	;Load a char
	LD   A, (HL)
	CP   CHR_CR
	JR   NZ, IsNotCR		; A == CR

	;Print CR and process next line.
	INC  HL
	RST  $10			;PRINT_A_1
	JR   NextLine

IsNotCR:
	CP   '.'
	JR   Z, SearchNum	; A == '.'

	CP   ':'
	JR   NC, TestSPC1	; A >= ':'

	CP   '0'
	JR   C, TestSPC1	; A < '0'

SearchNum:
	LD   B, H
	LD   A, NumMarker
	CPIR
	CALL $33B4			;STACK_NUM
	PUSH HL
		CALL $2DE3		;PRINT_FP
	POP  HL
	JR   GetCharLoop

TestSPC1:
	CP   ' '
	JR   C, TestREM		; A < ' '

	;Print char >= ' '
	RST  $10			;PRINT_A_1
	LD   A,(HL)

TestREM:
	CP   $EA			;RND token
	JR   NZ, TestQuote1	; A != RND

	INC  HL
TestREMLoop:
	LD   A, (HL)
	RST  $10			;PRINT_A_1
	INC  HL
	LD   DE,(LineEndAddr)	;Ingore chars after REM.
	push hl
	  or  a
	  sbc hl, de
	  ld  a, h
	  or  l
	pop  hl
	jr   nz, TestREMLoop
	JR   NextLine

TestQuote1:
	CP   '"'
	JR   NZ, SkipChar	; A != '"'

TestSPC2:
	INC  HL
	LD   A,(HL)
	CP   ' '
	JR   C, TestQuote2	; A < ' '

	;Print >= ' '.
	RST  $10			;PRINT_A_1
	LD   A,(HL)

TestQuote2:
	CP   '"'
	JR   NZ, TestSPC2	; A != '"'

SkipChar:
	INC  HL
	JR   GetCharLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutputFnct:
	cp	164
	jr	c, PrintIt	; A <= 164 ?

	sub		165
	ld		de, TKN_TABLE
	call	PO_SEARCH

NextTokenChar:
	ld		a, (de)
	inc		de
	bit		7, a
	jr		nz, LastChar
	call	PrintIt
	jr		NextTokenChar

LastChar:
	and		%01111111
	call	PrintIt
	ld		a, ' '

PrintIt:
	push	de
		ld	de, (DestinationAddr)
		ld	(de), a
		inc	de		
		ld	(DestinationAddr), de
	pop		de
	ret	

LineEndAddr		DEFW 0
ProgramStartAddr	DEFW 0
ProgramEndAddr		DEFW 0
DestinationAddr		DEFW 0

	ENDIF