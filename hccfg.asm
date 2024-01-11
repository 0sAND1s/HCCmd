	ifndef	_HCCFG_
	define	_HCCFG_

;HC specific code, for configuration

HC_CFG_PORT		EQU	$7E	;Configuration port for ROM selection (BASIC or CP/M) and SCREEN$ address selection.
HC_FLOPPY_PORT		EQU	7

HC_CFG_PORT_RAM1	EQU	$C5
HC_CFG_PORT_RAM2	EQU	$C7
HC_CFG_PORT_RAM_VAL	EQU	$FE	;Init value for RAM switch port.

;BASIC/CPM ROM selection
HC_CFG_ROM_BAS		EQU	%0
HC_CFG_ROM_CPM		EQU	%1

;Address for ROM paging: 0 or $E000
HC_CFG_ROM_0000		EQU	%00
HC_CFG_ROM_E000		EQU	%10

;Cfg. port Enable/Disable
HC_CFG_PORT_ENABLED	EQU	%000
HC_CFG_PORT_DISABLED	EQU	%100

;Video memory bank: $4000 or $C000
HC_CFG_VID_4000		EQU	%0000
HC_CFG_VID_C000		EQU	%1000


;Standar BASIC config. Leave config port enabled.
HC_CFG_BASIC		EQU	HC_CFG_ROM_BAS | HC_CFG_ROM_0000 | HC_CFG_VID_4000 | HC_CFG_PORT_ENABLED
;Standar CP/M config. Leave config port enabled.
HC_CFG_CPM		EQU	HC_CFG_ROM_CPM | HC_CFG_ROM_E000 | HC_CFG_VID_C000 | HC_CFG_PORT_ENABLED


HC_VID_ADDR_4000	EQU	$4000
HC_VID_ADDR_C000	EQU	$C000

	
	endif
	
