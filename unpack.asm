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
	ld		de, RUN_ADDR
	push	de
	include "dzx0.asm"
Binary:
	incbin "hccmd.zx0"
End:
