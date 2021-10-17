;Assemble this patch file with Flat Assembler (FASM), available at http://flatassembler.net/

use32

format binary as 'dll'

include 'patchmacros.inc'

;*** The EXE Header***
;In this part of the patch, you write down the original EXE header (use "objdump -h file.exe"), and copy down the sections list.
;objdump comes with GCC

;Look at output of "objdump -x file.exe", and write down some values:
;Idx Name          Size      VMA       LMA       File off  Algn
;  0 .text         00012e04  10001000  10001000  00001000  2**2
;  1 .rdata        00002ee1  10014000  10014000  00014000  2**2
;  2 .data         00001000  10017000  10017000  00017000  2**2
;  3 .rsrc         00000440  1001a000  1001a000  00018000  2**2
;  4 .reloc        0000184a  1001b000  1001b000  00019000  2**2

IMAGE_BASE = 0x10000000		;ImageBase from objdump output

;physical offsets of the sections
text_physical_offset  = 0x00001000
rdata_physical_offset = 0x00014000
data_physical_offset  = 0x00017000
rsrc_physical_offset  = 0x00018000
reloc_physical_offset = 0x00019000
;patch_physical_offset = reloc_physical_offset + 0x2000

;physical sizes of the offsets
text_physical_size	= rdata_physical_offset - text_physical_offset
rdata_physical_size	= data_physical_offset - rdata_physical_offset
data_physical_size	= rsrc_physical_offset - data_physical_offset
rsrc_physical_size	= reloc_physical_offset - rsrc_physical_offset
;reloc_pysical_size = patch_physical_offset - reloc_physical_offset
;patch_physical_size defined later

;VMAs of the sections
TEXT_VMA	= 0x10001000
RDATA_VMA	= 0x10014000
DATA_VMA	= 0x10017000
RSRC_VMA	= 0x1001A000
RELOC_VMA   = 0x1001B000
;PATCH_VMA	= 0x1001D000

;RVA = VMA - IMAGE_BASE
TEXT_RVA = TEXT_VMA - IMAGE_BASE
RDATA_RVA = RDATA_VMA - IMAGE_BASE
DATA_RVA = DATA_VMA - IMAGE_BASE
RSRC_RVA = RSRC_VMA - IMAGE_BASE
RELOC_RVA = RELOC_VMA - IMAGE_BASE
;PATCH_RVA = PATCH_VMA - IMAGE_BASE

;Virtual sizes of the sections
TEXT_VIRTUAL_SIZE	= RDATA_VMA - TEXT_VMA
RDATA_VIRTUAL_SIZE	= DATA_VMA - RDATA_VMA
DATA_VIRTUAL_SIZE	= RSRC_VMA - DATA_VMA
RSRC_VIRTUAL_SIZE	= RELOC_VMA - RSRC_VMA
;RELOC_VIRTUAL_SIZE  = PATCH_VMA - RELOC_VMA
;PATCH_VIRTUAL_SIZE	= (patch_physical_size + 0xFFF) / 0x1000 * 0x1000

;Conversions between memory addresses and EXE file addresses
TEXT_ORG   = TEXT_VMA - text_physical_offset
RDATA_ORG  = RDATA_VMA - rdata_physical_offset
DATA_ORG   = DATA_VMA - data_physical_offset
RSRC_ORG   = RSRC_VMA - rsrc_physical_offset
RELOC_ORG  = RELOC_VMA - reloc_physical_offset
;PATCH_ORG  = PATCH_VMA - patch_physical_offset

;Image size
;IMAGE_SIZE = PATCH_VMA + PATCH_VIRTUAL_SIZE - IMAGE_BASE

PE_LOCATION = 00F8h   ;Use a hex editor, and look for the text "PE" to see where it is.

; === Patching! ===

patchfile 'SactEngine.dll.$$$'

patchsection IMAGE_BASE ; === PE header ===

;patchat PE_LOCATION + 6 ; Increase number of sections
;  dw 5
;
;patchat PE_LOCATION + 50h ; Increase size of image
;  dd IMAGE_SIZE
;
;patchat PE_LOCATION + 0xF8 + 0x28 * 4  ;Add .patch section
;  dd '.pat','ch'		; Name
;  dd PATCH_VIRTUAL_SIZE	; Virtual size
;  dd PATCH_RVA			; RVA
;  dd patch_physical_size	; Physical size
;  dd patch_physical_offset	; Physical offset
;  dd 0,0,0			; Unused
;  dd 0E00000E0h		; Attributes

; ##################################################

;==========================
;  Patching .text section
;==========================
patchsection TEXT_ORG ; === .text section start ===

_TextOutA_replacement = 0 * 5 + 0x0043F000

patchat (0x10002368 - TEXT_ORG)
	mov edi,_TextOutA_replacement
	call edi
	POP EDI
	POP EBP
	MOV AL,1
	POP EBX
	RETN 4
patchtill (0x10002377 - TEXT_ORG)

; ##################################################

;==========================
;  Patching .rdata section
;==========================
patchsection RDATA_ORG ; === .rdata section start ===

;==========================
;  Patching .data section
;==========================
patchsection DATA_ORG ; === .data section start ===

;==========================
;  Patching .reloc section
;==========================
patchsection RELOC_ORG ; === .reloc section start ===
patchat (0x1001B084 - RELOC_ORG)
	db 0,0
patchtill (0x1001B086 - RELOC_ORG)


;=============
;  Variables
;=============

;declare variables here

;stack variables:  [ESP + xxxx + 4]  ;4 is the stack offset, this increases as you call or push more stuff

;==================
;  Patch section!
;==================

;patchsection PATCH_ORG
;patchat PATCH_VMA - PATCH_ORG
;
;patch_section_start:
;
;patch_section_end:
;patch_physical_size = patch_section_end - patch_section_start

patchend

; vim: ft=fasm
