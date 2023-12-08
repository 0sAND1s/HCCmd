	DEVICE ZXSPECTRUM48
	ORG $5B00 - (Unpack - Start)	
	
Start:	
	;Get offset of unpacker. BC is the argument x from RANDOMIZE USR x, the execution address.
	ld		hl, Unpack - Start	
	add		hl, bc	
	ld		bc, Binary - Unpack
	ld		de, Unpack
	ldir
	jp		Unpack
		
Unpack:
	;Check if previously unpacked it and run without unpacking again.	
	ld		a, (RUN_ADDR)
	cp		$CD	
	jp		z, RUN_ADDR	
			
	;Unpack to temp address.
	ld		de, 50000
	call	Unpacker	
	push	de
	
	;CLEAR variables, where our packed binary was, to avoid it being moved when new IF1 channels are created, overwriting our code.		
	ld		bc, 0
	call	$1EAF					;CLEAR address will be taken from RAMTOP.
	
	;Move from temp address to final address.
	pop		hl	
	ld		de, 50000
	or 		a
	sbc		hl, de
	ld		b, h
	ld		c, l
	ld		de, RUN_ADDR
	ld		hl, 50000
	ldir	
		
	jp		RUN_ADDR
Unpacker:	
	include "dzx0.asm"
Binary:
	incbin "hccmd.zx0"
End:
