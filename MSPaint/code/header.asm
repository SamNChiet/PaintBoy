SECTION "HOME", ROM0[$000]
; $0000 - $003F: RST handlers.
ds 64 ; TODO: Add RST

; $0040 - $0067: Interrupt handlers.
; TODO: Move this to its own ASM file and replace the JPs with mini functions
reti
ds 7    ; $0040 - VBlank Interrupt

reti
ds 7    ; $0048 - LCD Status Interrupt

reti
ds 7    ; $0050 - Timer Wraparound

reti
ds 7    ; $0058 - Serial Interrupt

reti
ds 7    ; $0060 - Joypad Interrupt


; $0068 - $00FF: 152 bytes of free space in ROM. Use for whatever you want ?
DS $98

SECTION "Org $100",ROM0[$100]
;*** Beginning of rom execution point ***

; $0100 - $0103: Startup Routine
jp Main ; There's only really enough space here for a jump.
nop

; * $0134 -$014F: ROM Header *
 NINTENDO_LOGO

;   |GAMETITLE|CODE| - 11 bytes of game title, 4 bytes of game code.
DB "0123456789ABCDE"    ; $0134: Game Title
DB $00				  ; $0143: Gameboy Color Compatibility Byte  [$00 - INCOMPATIBLE], [$80 - COMPATIBLE], [$C0 - EXCLUSIVE]
DB "YO"				 ; $0144 - $0145: New Licensee Code
DB $00				  ; $0146: Super Gameboy Compatibility Byte, used to indicate whenter the ROM has extra features on the Super Gameboy [$00 - UNSUPPORTED], [$03 - SUPPORTED]
DB CART_ROM_ONLY	    ; $0147: Cartridge type
DB CART_ROM_32K         ; $0148: ROM Size
DB CART_RAM_NONE		; $0149: External RAM Size
DB $01 				 ; $014A: Destination Code - for region-locking carts 
DB $33 				 ; $014B: Old Licensee Code
DB $00				  ; $014C: ROM Version number
DB $FF				  ; $041D: Header Checksum - patched by assembler w/ rgbfix
DW $FACE			    ; $014E-014F: Global checksum - patched by assembler
