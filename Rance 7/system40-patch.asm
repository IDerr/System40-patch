;Assemble this patch file with Flat Assembler (FASM), available at http://flatassembler.net/

use32

format binary as 'exe'

include 'patchmacros.inc'

;*** The EXE Header***
;In this part of the patch, you write down the original EXE header (use "objdump -h file.exe"), and copy down the sections list.
;objdump comes with GCC

;Look at output of "objdump -x file.exe", and write down some values:
;Idx Name          Size      VMA       LMA       File off  Algn
;  0 .text         0002b938  00401000  00401000  00001000  2**2
;  1 .rdata        00006b1e  0042d000  0042d000  0002d000  2**2
;  2 .data         00002000  00434000  00434000  00034000  2**2
;  3 .rsrc         00005a4c  00438000  00438000  00036000  2**2
;  4 .new00        00001000  0043e000  0043e000  0003c000  2**2

IMAGE_BASE = 0x00400000		;ImageBase from objdump output

;physical offsets of the sections
text_physical_offset	= 0x00001000
rdata_physical_offset	= 0x0002D000
data_physical_offset	= 0x00034000
rsrc_physical_offset	= 0x00036000
new00_physical_offset	= 0x0003C600
patch_physical_offset	= new00_physical_offset + 0x1000

;physical sizes of the offsets
text_physical_size	= rdata_physical_offset	- text_physical_offset
rdata_physical_size	= data_physical_offset	- rdata_physical_offset
data_physical_size	= rsrc_physical_offset	- data_physical_offset
rsrc_physical_size	= new00_physical_offset	- rsrc_physical_offset
new00_physical_size	= patch_physical_offset	- new00_physical_offset
;patch_physical_size defined later

;VMAs of the sections
TEXT_VMA	= 0x00401000
RDATA_VMA	= 0x0042D000
DATA_VMA	= 0x00434000
RSRC_VMA	= 0x00438000
NEW00_VMA	= 0x0043E000
PATCH_VMA	= 0x0043F000

;RVA = VMA - IMAGE_BASE
TEXT_RVA	= TEXT_VMA	- IMAGE_BASE
RDATA_RVA	= RDATA_VMA	- IMAGE_BASE
DATA_RVA	= DATA_VMA	- IMAGE_BASE
RSRC_RVA	= RSRC_VMA	- IMAGE_BASE
NEW00_RVA	= NEW00_VMA	- IMAGE_BASE
PATCH_RVA	= PATCH_VMA	- IMAGE_BASE

;Virtual sizes of the sections
TEXT_VIRTUAL_SIZE	= (text_physical_size	+ 0xFFF) / 0x1000 * 0x1000
RDATA_VIRTUAL_SIZE	= (rdata_physical_size	+ 0xFFF) / 0x1000 * 0x1000
DATA_VIRTUAL_SIZE	= (data_physical_size	+ 0xFFF) / 0x1000 * 0x1000
RSRC_VIRTUAL_SIZE	= (rsrc_physical_size	+ 0xFFF) / 0x1000 * 0x1000
NEW00_VIRTUAL_SIZE	= (new00_physical_size	+ 0xFFF) / 0x1000 * 0x1000
PATCH_VIRTUAL_SIZE	= (patch_physical_size	+ 0xFFF) / 0x1000 * 0x1000

;Conversions between memory addresses and EXE file addresses
TEXT_ORG	= TEXT_VMA	- text_physical_offset
RDATA_ORG	= RDATA_VMA	- rdata_physical_offset
DATA_ORG	= DATA_VMA	- data_physical_offset
RSRC_ORG	= RSRC_VMA	- rsrc_physical_offset
NEW00_ORG	= NEW00_VMA	- new00_physical_offset
PATCH_ORG	= PATCH_VMA	- patch_physical_offset

;Image size
IMAGE_SIZE = PATCH_VMA + PATCH_VIRTUAL_SIZE - IMAGE_BASE

PE_LOCATION = 0118h   ;Use a hex editor, and look for the text "PE" to see where it is.

; === Patching! ===

patchfile 'system40.exe.$$$'

patchsection IMAGE_BASE ; === PE header ===

patchat PE_LOCATION + 6 ; Increase number of sections
  dw 6
patchat PE_LOCATION + 50h ; Increase size of image
  dd IMAGE_SIZE

patchat PE_LOCATION + 0x80 ; change import table location and size
  dd (new_import_table - IMAGE_BASE)
  dd new_import_table_size

;patchat PE_LOCATION + 0xA0 ; remove relocation information
;  dd 0
;  dd 0
patchat PE_LOCATION + 0xF8 + 0x28 * 1  ;Change .rdata size
  dd '.rda','ta'
  dd RDATA_VIRTUAL_SIZE
  dd RDATA_RVA
  dd new_rdata_physical_size
  dd rdata_physical_offset
  dd 0,0,0			; Unused
  dd 0E00000E0h		; Attributes

patchat PE_LOCATION + 0xF8 + 0x28 * 5  ;Add .patch section
  dd '.pat','ch'		; Name
  dd PATCH_VIRTUAL_SIZE	; Virtual size
  dd PATCH_RVA			; RVA
  dd patch_physical_size	; Physical size
  dd patch_physical_offset	; Physical offset
  dd 0,0,0			; Unused
  dd 0E00000E0h		; Attributes

; ##################################################

;==========================
;  Patching CODE section
;==========================
patchsection TEXT_ORG ; === CODE section start ===

;TODO: patch anything in the CODE section?

; ##################################################

;==========================
;  Patching RDATA section
;==========================
patchsection RDATA_ORG ; === RDATA section start ===

rdata_section_start:

;moved from 325C0 to 33B20

patchat (0x00433B20 - RDATA_ORG)
new_import_table:
;copied from 325C0 in the file

	dd 0x00032724,0x00000000,0x00000000,0x00032B4E,0x0002D058
	dd 0x00032A4C,0x00000000,0x00000000,0x00032C5A,0x0002D380
	dd 0x00032744,0x00000000,0x00000000,0x00032F46,0x0002D078
	dd 0x000328D4,0x00000000,0x00000000,0x00033516,0x0002D208
	dd 0x000326F0,0x00000000,0x00000000,0x000335E2,0x0002D024
	dd 0x00032A88,0x00000000,0x00000000,0x00033600,0x0002D3BC
	dd 0x000326CC,0x00000000,0x00000000,0x00033674,0x0002D000
	dd 0x000328CC,0x00000000,0x00000000,0x00033692,0x0002D200
	dd 0x00032AA0,0x00000000,0x00000000,0x000336D4,0x0002D3D4
	dd 0x00032A3C,0x00000000,0x00000000,0x00033720,0x0002D370
	dd 0x000326E8,0x00000000,0x00000000,0x00033742,0x0002D01C
	dd 0x00032A90,0x00000000,0x00000000,0x0003374E,0x0002D3C4
	dd new_import_lookup_table - IMAGE_BASE, 0, 0, new_dll_name - IMAGE_BASE, new_import_thunk - IMAGE_BASE
;	dd new_import_lookup_table_2 - IMAGE_BASE, 0, 0, new_dll_name_2 - IMAGE_BASE, new_import_thunk_2 - IMAGE_BASE
	dd 0x00000000,0x00000000,0x00000000,0x00000000,0x00000000


new_import_table_size = $ - new_import_table

new_import_lookup_table:
	dd textoutw_name - IMAGE_BASE
	dd 0
new_dll_name:
	db "GDI32.dll",0
	dd 0
textoutw_name:
	dw 0x250
	db "TextOutW",0,0
	dd 0

;new_import_lookup_table_2:
;	dd multibytetowidechar_name - IMAGE_BASE
;	dd 0
;new_dll_name_2:
;	db "KERNEL32.dll",0
;	dd 0
;multibytetowidechar_name:
;	dw 0x267
;	db "MultiByteToWideChar",0,0
;	dd 0

new_import_thunk:
TextOutW_thunk:
	dd textoutw_name - IMAGE_BASE
	dd 0

;new_import_thunk_2:
;MultiByteToWideChar_thunk:
;	dd textoutw_name - IMAGE_BASE
;	dd 0

patchat (DATA_VMA - RDATA_ORG)

rdata_section_end:
new_rdata_physical_size = rdata_section_end - rdata_section_start

;=============
;  Variables
;=============
;declare variables here

;stack variables:  [ESP + xxxx + 4]  ;4 is the stack offset, this increases as you call or push more stuff

;functions
MultiByteToWideChar = 0x0042D130
;WideCharToMultiByte = 0x0042D164

;==================
;  Patch section!
;==================

patchsection PATCH_ORG
patchat PATCH_VMA - PATCH_ORG

patch_section_start:

	;Jump table is at 0x0043F000
_TextOutA_replacement:
	jmp near TextOutA_replacement

TextOutA_replacement:
;wraps TextOutA to change halfwidth katakana into accented characters
;Also calls TextOutW for Japanese characters as well, so it's also a locale fix for displaying text.

;from original stack location (add 0x100)
.string = 0x10
.size = 0x14

;from new stack location
.stringbuffer1 = 0x10
.stringbuffer2 = 0x20

	;ESP+00 = return address
	;ESP+04 = hdc
	;ESP+08 = xstart
	;ESP+0C = ystart
	;ESP+10 = String
	;ESP+14 = Size (should be 2)
	
	;move stack forward 0x100 bytes (so other variables don't get clobbered?)
	sub esp,0xEC
	push eax
	push ebx
	push ecx
	push edx
	push edi
	
	;is text halfwidth katakana?
	mov eax,[esp+0x100 + .string]
	mov bl,[eax]
	cmp bl,0x80
	jb .convert_ansi
	cmp bl,0xA0
	jb .shiftjis
	cmp bl,0xE0
	jae .shiftjis
.convert_ansi:
	;convert from fake western encoding to unicode
	;by adding 0x20 to characters, then calling MultiByteToWideChar
	mov ecx,esp
	add ecx,.stringbuffer2
.convert_loop:
	mov bl,[eax]
	cmp bl,0
	je .done_converting
	cmp bl,0x80
	jb .dontconvertchar
	add bl,0x20
.dontconvertchar:
	mov [ecx],bl
	inc eax
	inc ecx
	jmp .convert_loop
.done_converting:
	mov [ecx],bl
	mov edx,[esp+0x100 + .size]
	mov eax,esp
	add eax,.stringbuffer1
	mov ebx,esp
	add ebx,.stringbuffer2
	
	;arguments of MultiByteToWideChar
	push 0x08	;output buffer length
	push eax	;output buffer (stringbuffer 1)
	push edx	;input byte count (always 2)
	push ebx	;input buffer (stringbuffer 2)
	push 0		;flags
	push 1252	;code page Windows 1252 (Western Encoding)
	call dword [MultiByteToWideChar]
	
	mov ebx,esp
	add ebx,.stringbuffer1
	;transfer original stack arguments
	mov eax,[esp+0x114]
	push eax	;size in characters (always 2)
	push ebx	;input buffer (stringbuffer 1)
	mov eax,[esp+0x114]
	push eax	;ystart
	mov eax,[esp+0x114]
	push eax	;xstart
	mov eax,[esp+0x114]
	push eax	;hdc
	call dword [TextOutW_thunk]
	
	pop edi
	pop edx
	pop ecx
	pop ebx
	add esp,0xF0
	MOV EDX,[EDI+0x74]
	MOV ECX,[EDI+0x70]
	retn 0x14
	
.shiftjis:
	;convert from shift-jis to unicode
	mov edx,[esp+0x100 + .size]
	mov ebx,esp
	add ebx,.stringbuffer1
	
	;arguments of MultiByteToWideChar
	push 0x08  ;buffer size in characters (8)
	push ebx   ;output buffer (stringbuffer 1)
	push edx   ;size in characters (always 2)
	push eax   ;input text address
	push 0     ;flags
	push 932   ;code page 932 (Japanese Shift-JIS)
	call dword [MultiByteToWideChar]
	
	mov ebx,esp
	add ebx,.stringbuffer1
	;transfer original stack arguments
	mov eax,[esp+0x114]
	push eax	;size in characters (always 2)
	push ebx	;input buffer (stringbuffer 1)
	mov eax,[esp+0x114]
	push eax	;ystart
	mov eax,[esp+0x114]
	push eax	;xstart
	mov eax,[esp+0x114]
	push eax	;hdc
	call dword [TextOutW_thunk]
	
	pop edi
	pop edx
	pop ecx
	pop ebx
	MOV EDX,[EDI+0x74]
	MOV ECX,[EDI+0x70]
	add esp,0xF0
	retn 0x14

	
patch_section_end:
patch_physical_size = patch_section_end - patch_section_start

patchend

; vim: ft=fasm
