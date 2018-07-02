include "includes/HARDWARE.INC"
include "includes/constants.inc"
include "../assets/tiles.z80"
include "../assets/basictiles.z80"
include "header.asm"
include "game.asm"

SECTION "MainProgram",ROM0[$0150]
Main:
 REPT 7
 ld a, 0 
 ENDR

 di 
 ld sp, $FFFF ; Reset Stack

 call WaitVBlank
 call TurnLCDOff
 
 ; Configure LCDC:
 ;   | BG Characters, 8800
 ;   | BG Codes, 9800-98FF
 ;   | OBJ off | BG on |Window Off
 ld a, %00000011
 ld [rLCDC], a

 ; Set BG Palette [DMG]
 ld a, %11100100
 ld [rBGP], a  ; Set Background palette
 ld [rOBP0], a ; Set Sprite Palette 0
 ld [rOBP1], a ; Set Sprite Palette 1

 call LoadSpriteTiles
 call LoadBGTiles_UI
 
 call SetupCanvas
 
 call CopyDMATransferToHRAM
 call ResetShadowOAM
 call DMARoutine

 call TurnLCDOn
 
 call GameReset

.whileRunning:
 call WaitVBlank
 call ReadInput
 call GameLoop
 call DMARoutine
 jp .whileRunning

LoadSpriteTiles:
 ld de, 16
 ld bc, ReticleTile
 ld hl, MM_SPRITE_CHAR_START
 call MemCopy
  ret


; - CORE FUNCTIONS -
WaitVBlank:: ; TODO: Replace this with something more battery-saving
 ld a, [rLY]
 cp 144
 jr nz, WaitVBlank
 ret

TurnLCDOff::
 ld hl, rLCDC
 res 7, [hl]
  ret

TurnLCDOn::
 ld hl, rLCDC
 set 7, [hl]
  ret

ReadInput::
 ldh a, [input_byte]
 ldh [last_input_byte], a ; Cache input in last_input_byte
 ld a, %00010000 ; Bit to activate port P14
 ld [rJoypad], a ; Reads U,D,L,R keys
 ldh a, [rJoypad] ; read UDLR
 ldh a, [rJoypad] ; Kill some cycles
 cpl ; Complement A (flip bits)
 and $0F ; mask out the lower four bits, which don't contain the actual button inputs 
 swap a ; flip nybbles of A (Up, Down, Left, Right, A, B,  Select, Start)
 ld b, a ; Store it in B
 ld a, %00100000 ; Bit to activate port P15
 ld [rJoypad], a ; Reads A,B,Select,Start keys
 ld a, [rJoypad] ; Kill some cycles
 ld a, [rJoypad] ; Kill some cycles
 ld a, [rJoypad] ; Kill some cycles
 ld a, [rJoypad] ; Kill some cycles
 ld a, [rJoypad] ; Kill some cycles
 ld a, [rJoypad] ; Kill some cycles
 cpl
 and $0F
 or b
 ldh [input_byte], a
 ;Get Changed Input Byte
 ;ld B, A  
 ;ld A, [last_input_byte] ; B: Current Input Byte, A: Last   Input Byte
 ;xor B ; Get changed bits
 ; and B ; Only get buttons pressed this frame 
 ;ld [ChangedInputByte], A
  ret

; - Memory Functions -
MemClear::
 ; Clears bc bytes starting at hl with value in a.
 ; bc can be a maximum of $7fff, since it checks bit 7 of b when looping.
 dec bc
.clearLoop
 ld [hl+], a
 dec bc
 bit 7, b
 jr z, .clearLoop
  ret

MemCopy::
 ; DE = block size
 ; BC = source address
 ; HL = destination address
 dec DE
.memcpy_loop:
 ld A, [BC]
 ld [HL], A
 inc BC
 inc HL
 dec DE
.memcpy_check_limit:
 ld A, E
 cp $00
 jr nz, .memcpy_loop
 ld A, D
 cp $00
 jr nz, .memcpy_loop
  ret

ResetShadowOAM::
 ld hl, MM_SHADOW_OAM_START
 ld bc, MM_SHADOW_OAM_LENGTH
 xor a
 call MemClear

 ; Set up reticle
 ld a, 0
 ld [MM_SHADOW_OAM_START + 2], a ; Set char code to 0
 ld a, %000000
 ld [MM_SHADOW_OAM_LENGTH + 3], a ; reset all attributes
 ret

CopyDMATransferToHRAM:
 ld c, $80
 ld b, 10
 ld hl, DMADATA
.L2:
 ld a, [hl+] 
 ld [c], a
 inc c
 dec b
 jr nz, .L2
 ret

DMADATA:
 ld a, $c0
 ld [rDMA], a
 ld a, 40
.L1: dec a
 jr nz, .L1
 ret

; - Graphics Functions -
LoadBGTiles_General:
 ld de, BGTilesLen
 ld bc, BGTileLabel
 ld hl, MM_BG_CHAR_START
 call MemCopy
  ret

; This is a custom routine for the MS Paint program, loading graphics after the canvas tiles instead of at the start of tile char memory 
UI_BG_CHAR_START EQU $9700
LoadBGTiles_UI:
 ld de, BGTilesLen
 ld bc, BGTileLabel
 ld hl, UI_BG_CHAR_START
 call MemCopy
  ret