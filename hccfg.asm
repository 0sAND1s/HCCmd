	ifndef	_HCCFG_
	define	_HCCFG_

;HC specific code, for configuration

HC_CFG_PORT			EQU	$7E

;BASIC/CPM ROM selection
HC_CFG_ROM_BAS		EQU	%0
HC_CFG_ROM_CPM		EQU	%1

;Address for ROM paging: 0 or $E000
HC_CFG_ROM_0000		EQU %00
HC_CFG_ROM_E000		EQU %10

;Cfg. port Enable/Disable
HC_CFG_PORT_DIS		EQU %000
HC_CFG_PORT_EN		EQU	%100

;Video memory bank: $4000 or $C000
HC_CFG_VID_4000		EQU	%0000
HC_CFG_VID_C000		EQU	%1000


;Standar BASIC config
HC_CFG_BASIC		EQU	HC_CFG_ROM_BAS | HC_CFG_ROM_0000 | HC_CFG_VID_4000
;Standar CP/M config
HC_CFG_CPM			EQU	HC_CFG_ROM_CPM | HC_CFG_ROM_E000 | HC_CFG_VID_C000


HC_VID_BANK0		EQU	$4000
HC_VID_BANK1		EQU	$C000

	endif