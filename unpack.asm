
	ORG $5B00 - (UnpackSetup - Start)	
	
TempAddr	EQU	$9000
CLEAR_ADDR	EQU	$1EAF

	include "hccfg.asm"
	
Start:	
	;Get offset of unpacker. BC is the argument x from RANDOMIZE USR x, the execution address.
	ld	hl, UnpackSetup - Start	
	add	hl, bc	
	ld	bc, Binary - UnpackSetup
	ld	de, UnpackSetup
	ldir
	jp	UnpackSetup
		
UnpackSetup:
	;Check if previously unpacked it and run without unpacking again.	
	ld	a, (RUN_ADDR)
	cp	$CD	
	jp	z, RUN_ADDR	
			
	;Unpack to temp address.
	ld	de, TempAddr
	call	Unpacker	
	push	de
	
	;CLEAR variables, where our packed binary was, to avoid it being moved when new IF1 channels are created, overwriting our code.		
	ld	bc, 0
	call	CLEAR_ADDR				;CLEAR address will be taken from RAMTOP.
	
	;Move from temp address to final address.
	pop	hl	
	ld	de, TempAddr
	or 	a
	sbc	hl, de
	ld	b, h
	ld	c, l
	ld	de, RUN_ADDR
	ld	hl, TempAddr
	push	bc
	ldir	
	pop	bc
	
	;Copy program in the extra 16KB RAM paged at 0-4000, for using it later, if file copy operation overwrites HCCmd.
	ld	a, HC_CFG_ROM_CPM | HC_CFG_ROM_E000
	di
	out	(HC_CFG_PORT), a
	
	ld	hl, TempAddr
	ld	de, 0
	ldir
	
	ld	a, HC_CFG_ROM_BAS | HC_CFG_ROM_0000
	out	(HC_CFG_PORT), a
	ei
		
	jp	RUN_ADDR
Unpacker:	
	include "dzx0.asm"
Binary: