SECTION "HRAMVars", HRAM[$FF90]
; CORE VARS
input_byte:: ds 1
last_input_byte:: ds 1

; OTHER VARS
hr_paintcursor_x: ds 1
hr_paintcursor_y: ds 1
hr_tile: ds 16
tile_x: ds 1
tile_y: ds 1

SECTION "MainPaint", ROM0

GameLoop::
 call MoveCursor
 
 ldh a, [input_byte]  ; If A pressed, call PaintPixel
 bit JOY_A, a
 jr z, .skipPaintPixel
 call PaintPixel
.skipPaintPixel

  ret

MoveCursor:
; Update Paintcursor position
 ldh a, [input_byte]
 ld b, a

CURSOR_SPEED EQU 1
 ldh a, [hr_paintcursor_x]

.moveRight
 ; If we're at the right edge of the canvas, skip to moveleft
 cp (8*16) - 1
 jp nc, .moveLeft
 bit JOY_RIGHT, b
 jr z, .moveLeft
 add a, CURSOR_SPEED 
.moveLeft
 ; If we're at the left edge of the canvas, skip to switchAxis
 cp 0
 jp z, .switchAxisToY
 bit JOY_LEFT, b
 jr z, .switchAxisToY
 sub a, CURSOR_SPEED
.switchAxisToY
 ldh [hr_paintcursor_x], a
 ldh a, [hr_paintcursor_y]
.moveUp
 ; If we're at the top edge of the canvas, skip to moveDown
 cp 0
 jp z, .moveDown
 bit JOY_UP, b
 jr z, .moveDown
 sub a, CURSOR_SPEED 
.moveDown
 ; If we're at the bottom edge of the canvas, skip to doneMoving
 cp (8*14) - 1
 jp nc, .doneMoving
 bit JOY_DOWN, b
 jr z, .doneMoving
 add a, CURSOR_SPEED
.doneMoving 
 ldh [hr_paintcursor_y], a
 
 ; Set cursor sprite position in OAM
 ldh a, [hr_paintcursor_x]
 add 4
 ld [RETICLE_OAM_X], a
 ldh a, [hr_paintcursor_y]
 add 12
 ld [RETICLE_OAM_Y], a
  ret

PaintPixel:
; Find position of tile (x shift 8)
 ldh a, [hr_paintcursor_x]
 rightShift a, 3
 ldh [tile_x], a

 ld a, [hr_paintcursor_y]
 rightShift a, 3
 ldh [tile_y], a

 ; Tile Data Mem Loc = Start + ((TileX + (TileY * CanvasWidthTiles)) * CharDataBytes [16])
 ; TODO: Currently multiplying TileX and TileY*CanvasWidthTiles by CharDataBytes individually - collapse this down?
 ; Pixel = hr_paintcursor_x & 00001111 (mask off last 4 bits)
 
 ld hl, MM_BG_CHAR_START ; hl = start address
 ld d, 0
 ld a, [tile_x]
 ld e, a                 ; de = tile_x
 leftShift16_4bm d,e, 4  ; de *= BytesPerTile | de << 4
 add hl, de			  ; hl += tile_x*BytesPerTile

 ld a, [tile_y]
 ld e,a                  ; de = tile_y
 leftShift16_4bm d,e, 4  ; de *= CanvasWidthTiles[16]
 leftShift16_4bm d,e, 4  ; de *= BytesPerTile = [16]
 add hl, de              ; hl += tile_x*BytesPerTile

; WRITE PIXEL TO VRAM:
 ;---- LOAD C WITH A PIXEL MASK ----
 ldh a, [hr_paintcursor_x]
 and %00000111
 ld b, a ; Store pixel number in b
 ld a, %10000000 ; Load A with the leftmost pixel mask

 ; TODO: For lord's sake find a better non-destructive way of checking whether a non-A register is zero - amateur hour
 swap b ; Check if we're on the 0th pixel (sets z flag)
 jr z, .writeMask ; Skip shifting the pixel mask
 swap b ; swap b back to its original form

.shiftMaskX
  srl a
  dec b
  jr z, .writeMask
  jr .shiftMaskX
.writeMask 
 ld c, a ; Load C with the pixel  mask

 ;---- LOAD HL WITH THE FIRST BYTE OF THE TILE ROW  ----
 ldh a, [hr_paintcursor_y]
 and %00000111
 ld b, a ; Load B with the row number

 ; TODO: For lord's sake find a better non-destructive way of checking whether a non-A register is zero
 swap b ; Check if we're on the 0th row (sets z flag)
 jr z, .writePixel ; Skip shifting the row
 swap b ; swap b back to its original form

.shiftHLRow
  inc hl
  inc hl
  dec b
  jr z, .writePixel
  jr .shiftHLRow
 
 ;---- WRITE PIXEL ----
.writePixel
 ld a, [hl]  ; Load A with first byte of tile row
 or c        ; Write the pixel into A
 ld [hl+], a ; Write A back out to the first byte of tile row, move HL to second byte
 ld [hl], a  ; Write A back out to the second byte of the tile row (they're the same for now)
 ; TODO: Set separate bits for low and high bytes of pixels for each tile. Write full color palette color.
  ret

GameReset::
 call TurnLCDOff
 call SetupCanvas
 call TurnLCDOn
 
 ld a, 7 ; Reset cursor pos
 ldh [hr_paintcursor_x], a
 ldh [hr_paintcursor_y], a
  ret

SetupCanvas: ; TODO: Add UI
 ; Clear all bg codes to last character
 ld hl, MM_BG_CODES_START
 ld bc, 32*32 ; all tiles 
 ld a, $7F
 call MemClear

 ; SET CANVAS TILE CODES
 ; HACK: This generates an obscene amount of code, manually sets each tile in the canvas.
 ; TODO: Replace with a loop
; 1: Starting Tile Code
; 2: Row Starting Map Code Address (in memory, the bg char data go 128-255 then 0-127, starting at 0x8800)
SETUP_TILE_ROW: MACRO
 ld a, \1
 ld hl, \2
 REPT CANVAS_WIDTH
  ld [hl+], a
  inc a 
 ENDR
ENDM

 SETUP_TILE_ROW $80, $9800
 SETUP_TILE_ROW $90, $9820
 SETUP_TILE_ROW $A0, $9840
 SETUP_TILE_ROW $B0, $9860
 SETUP_TILE_ROW $C0, $9880
 SETUP_TILE_ROW $D0, $98A0
 SETUP_TILE_ROW $E0, $98C0
 SETUP_TILE_ROW $F0, $98E0
 SETUP_TILE_ROW $00, $9900
 SETUP_TILE_ROW $10, $9920
 SETUP_TILE_ROW $20, $9940
 SETUP_TILE_ROW $30, $9960
 SETUP_TILE_ROW $40, $9980
 SETUP_TILE_ROW $50, $99A0
 SETUP_TILE_ROW $60, $99C0

 ld a, 0
 ld [$8ff0], a
ret

SetupDebugBackground::
 ; Clear all bg map codes to last character
 ld hl, MM_BG_CODES_START
 ld bc, 32*32 ; all tiles 
 ld a, $FF
  call MemClear
ret