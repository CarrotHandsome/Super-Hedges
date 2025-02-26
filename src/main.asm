INCLUDE "hardware.inc"
INCLUDE "game.inc"

SECTION "Header", ROM0[$100]
    jp EntryPoint

    ds $150 - @, 0; make room for header

EntryPoint:
;do not turn off LCD outside VBlank
call WaitVBlank

;turn LCD off
ld a, 0
ld [rLCDC], a

;copy tile data
ld de, Tiles
ld hl, $9000
ld bc, TilesEnd - Tiles
call Memcopy

;copy tilemap
ld de, Tilemap
ld hl, $9800
ld bc, TilemapEnd - Tilemap
call Memcopy

ld a, 0
ld b, 160
ld hl, _OAMRAM
ClearOam:
ld [hli], a
dec b
jp nz, ClearOam

;set object attributes
ld hl, _OAMRAM
ld a, 128 + 16
ld [hli], a
ld a, 16 + 8
ld [hli], a
ld a, 0
ld [hli], a
ld [hl], a

;turn lcd on
ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
ld [rLCDC], a

;during first blank frame, initialize display registers
ld a, %11100100
ld [rBGP], a
ld a, %11100100
ld [rOBP0], a

;initialize global variables
ld a, 0
ld [wFrameCounter], a
ld [wCurKeys], a
ld [wNewKeys], a
ld [wScratchA], a
ld [wScratchB], a
ld a, $7F
ld [wSelectedTileIndex], a

call InitializeRandom
call InitializeCardLocations


call GenerateRandomDecks

;call RenderHand

Main:
;wait till its not Vblank
ld a, [rLY]
cp a, 144
jp nc, Main
WaitVBlank2:
ld a, [rLY]
cp 144
jp c, WaitVBlank2

call UpdateKeys
CheckB:
    ld a, [wNewKeys]
    and a, PADF_B
    jp z, CheckA
    call ClearEncounters
    ld hl, ScenarioCards
    call DrawFromDeck
    call RenderEncounters
CheckA:
    ld a, [wNewKeys]
    and a, PADF_A
    jp z, CheckLeft   
    call ClearHand
    ;call PlayerDraw
    ld hl, PlayerCards
    call DrawFromDeck
    call RenderHand
    ; ld a, $10
    ; ld hl, PlayerHand
    ; call CreateCard
    ; call RenderHand



CheckLeft:
ld a, [wCurKeys]
and a, PADF_LEFT
jp z, CheckRight

Left:
ld a, [_OAMRAM + 1]
dec a
;dont move past edge
cp a, [hl]
jp z, Main
ld [_OAMRAM + 1], a
jp Main

CheckRight:
ld a, [wCurKeys]
and a, PADF_RIGHT
jp z, Main

Right:
ld a, [_OAMRAM + 1]
inc a
cp a, 105
jp z, Main
ld [_OAMRAM + 1], a
jp Main

InitializeRandom:   
    GetTimer: 
    ld a, [$FF04] ;ff05 is timer register
    add 0
    jp z, GetTimer
    ld [wRandom], a
    ld [wRandom + 1], a
    call Random
    ret
UpdateKeys:
    ; Poll half the controller
    ld a, P1F_GET_BTN
    call .onenibble
    ld b, a ; B7-4 = 1; B3-0 = unpressed buttons

    ; Poll the other half
    ld a, P1F_GET_DPAD
    call .onenibble
    swap a ; A3-0 = unpressed directions; A7-4 = 1
    xor a, b ; A = pressed buttons + directions
    ld b, a ; B = pressed buttons + directions

    ; And release the controller
    ld a, P1F_GET_NONE
    ldh [rP1], a

    ; Combine with previous wCurKeys to make wNewKeys
    ld a, [wCurKeys]
    xor a, b ; A = keys that changed state
    and a, b ; A = keys that changed to pressed
    ld [wNewKeys], a
    ld a, b
    ld [wCurKeys], a
    ret

.onenibble
    ldh [rP1], a ; switch the key matrix
    call .knownret ; burn 10 cycles calling a known ret
    ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
    ldh a, [rP1]
    ldh a, [rP1] ; this read counts
    or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
.knownret
    ret

SECTION "Tile Data", rom0
Tiles:        
    Ranks:    
    DB $7F, $7F, $80, $80, $80, $90, $00, $B0
DB $80, $90, $00, $90, $00, $90, $80, $10
DB $7F, $7F, $80, $80, $80, $B0, $00, $88
DB $80, $98, $00, $A0, $00, $A8, $80, $38
DB $7F, $7F, $80, $80, $80, $B8, $00, $88
DB $80, $90, $00, $88, $00, $88, $80, $30
DB $7F, $7F, $80, $80, $80, $88, $00, $A8
DB $80, $A8, $00, $B8, $00, $88, $80, $08
DB $7F, $7F, $80, $80, $80, $B8, $00, $A0
DB $80, $B0, $00, $88, $00, $A8, $80, $10
DB $7F, $7F, $80, $80, $80, $88, $00, $90
DB $80, $B0, $00, $A8, $00, $A8, $80, $10
DB $7F, $7F, $80, $80, $80, $B8, $00, $88
DB $80, $88, $00, $88, $00, $88, $80, $08
DB $7F, $7F, $80, $80, $80, $90, $00, $A8
DB $80, $90, $00, $A8, $00, $A8, $80, $10
DB $7F, $7F, $80, $80, $80, $B8, $00, $A8
DB $80, $A8, $00, $98, $00, $88, $80, $08
DB $7F, $7F, $80, $80, $80, $92, $00, $B5
DB $80, $95, $00, $95, $00, $95, $80, $12
DB $7F, $7F, $80, $80, $80, $91, $00, $B3
DB $80, $91, $00, $91, $00, $91, $80, $11
DB $7F, $7F, $80, $80, $80, $96, $00, $B1
DB $80, $93, $00, $94, $00, $95, $80, $17
DB $7F, $7F, $80, $80, $80, $97, $00, $B1
DB $80, $92, $00, $91, $00, $91, $80, $16
DB $7F, $7F, $80, $80, $80, $91, $00, $B5
DB $80, $95, $00, $97, $00, $91, $80, $11
DB $7F, $7F, $80, $80, $80, $97, $00, $B4
DB $80, $96, $00, $91, $00, $95, $80, $12
DB $7F, $7F, $80, $80, $80, $91, $00, $B2
DB $80, $96, $00, $95, $00, $95, $80, $12
DB $7F, $7F, $80, $80, $80, $97, $00, $B1
DB $80, $91, $00, $91, $00, $91, $80, $11
DB $7F, $7F, $80, $80, $80, $92, $00, $B5
DB $80, $92, $00, $95, $00, $95, $80, $12
DB $7F, $7F, $80, $80, $80, $97, $00, $B5
DB $80, $95, $00, $93, $00, $91, $00, $11
DB $7F, $7F, $80, $80, $80, $B2, $00, $8D
DB $80, $8D, $00, $95, $00, $A5, $80, $3A
DB $7F, $7F, $80, $80, $80, $B1, $00, $8B
DB $80, $89, $00, $91, $00, $A1, $80, $39
DB $7F, $7F, $80, $80, $80, $B6, $00, $89
DB $80, $89, $00, $92, $00, $A4, $80, $3B
DB $7F, $7F, $80, $80, $80, $B6, $00, $89
DB $80, $8A, $00, $91, $00, $A5, $80, $3A
DB $7F, $7F, $80, $80, $80, $B1, $00, $8D
DB $80, $8D, $00, $97, $00, $A1, $80, $39
DB $7F, $7F, $80, $80, $80, $B7, $00, $8C
DB $80, $8E, $00, $91, $00, $A5, $80, $3A
DB $7F, $7F, $80, $80, $80, $B1, $00, $8A
DB $80, $8E, $00, $95, $00, $A5, $80, $3A
DB $7F, $7F, $80, $80, $80, $B7, $00, $89
DB $80, $89, $00, $91, $00, $A1, $80, $39
DB $7F, $7F, $80, $80, $80, $B2, $00, $8D
DB $80, $8A, $00, $95, $00, $A5, $80, $3A
DB $7F, $7F, $80, $80, $80, $B7, $00, $8D
DB $80, $8D, $00, $93, $00, $A1, $80, $39
DB $7F, $7F, $80, $80, $80, $B2, $00, $8D
DB $80, $95, $00, $8D, $00, $AD, $80, $12
DB $7F, $7F, $80, $80, $80, $B1, $00, $8B
DB $80, $91, $00, $89, $00, $A9, $80, $11
DB $7F, $7F, $80, $80, $80, $B6, $00, $89
DB $80, $91, $00, $8A, $00, $AC, $80, $17


    Suits:
    DB $9C, $20, $30, $CE, $AE, $51, $2A, $D5
DB $B2, $CD, $3E, $C1, $80, $BE, $7F, $7F
DB $80, $08, $00, $88, $80, $1C, $08, $94
DB $88, $B6, $1C, $A2, $BE, $C1, $7F, $7F
DB $9C, $1C, $3E, $80, $BE, $3E, $3E, $80
DB $BE, $BE, $1C, $80, $88, $88, $7F, $7F
DB $C9, $49, $2A, $AA, $80, $1C, $63, $FF
DB $80, $9C, $2A, $AA, $C9, $C9, $7F, $7F
DB $9C, $63, $08, $B6, $88, $1C, $3E, $BE
DB $88, $9C, $08, $B6, $9C, $E3, $7F, $7F



    LeftArt:
    DB $00, $00, $00, $00, $00, $00, $01, $01
    DB $03, $02, $05, $04, $0B, $0D, $17, $1A
    DB $63, $63, $1C, $1C, $09, $49, $2B, $49
    DB $2B, $49, $23, $41, $41, $01, $A5, $24
    DB $07, $07, $0A, $0D, $14, $1B, $29, $36
    DB $24, $2B, $41, $7E, $88, $D7, $80, $FE
    DB $0F, $0F, $10, $10, $24, $24, $40, $60
    DB $80, $E0, $60, $60, $30, $20, $10, $10
    DB $1F, $10, $2E, $31, $5E, $61, $AE, $D1
    DB $F6, $89, $F2, $8D, $BC, $C3, $6B, $55
    DB $00, $00, $98, $00, $80, $01, $41, $03
    DB $63, $46, $26, $3C, $2C, $20, $1F, $1F
    DB $5C, $63, $3F, $28, $7F, $40, $FF, $80
    DB $7F, $40, $3F, $30, $0E, $0D, $03, $03
    DB $10, $10, $10, $10, $18, $10, $0C, $08
    DB $06, $04, $03, $03, $00, $00, $00, $00




    MiddleArt:
    DB $7E, $7E, $FF, $81, $81, $00, $5A, $42
    DB $18, $00, $FF, $7E, $FF, $81, $FF, $00
    DB $00, $00, $00, $00, $00, $00, $00, $00
    DB $00, $00, $E3, $E3, $B6, $14, $14, $08
    DB $FC, $FC, $AB, $57, $04, $BA, $10, $EF
    DB $42, $B5, $21, $DE, $88, $77, $46, $A9
    DB $00, $00, $80, $80, $40, $40, $20, $20
    DB $18, $18, $04, $04, $02, $02, $84, $01
    DB $FF, $00, $BD, $42, $BD, $42, $BD, $42
    DB $BD, $42, $BD, $42, $99, $66, $FF, $3C
    DB $00, $00, $10, $01, $11, $02, $20, $02
    DB $40, $02, $00, $7E, $20, $C2, $40, $80
    DB $40, $BF, $89, $76, $E0, $1D, $F0, $07
    DB $FC, $03, $FF, $00, $FF, $00, $FF, $81
    DB $A2, $00, $55, $00, $22, $00, $1F, $00
    DB $00, $00, $80, $08, $AA, $BB, $D5, $F7


    RightArt:
    DB $00, $00, $00, $00, $80, $80, $40, $40
DB $C0, $40, $A0, $20, $D0, $B0, $E8, $58
DB $00, $00, $00, $00, $00, $00, $03, $03
DB $04, $05, $FC, $FD, $0C, $01, $00, $01
DB $00, $00, $00, $00, $80, $80, $40, $C0
DB $A0, $60, $50, $B0, $90, $50, $08, $F8
DB $00, $00, $00, $00, $00, $00, $00, $00
DB $00, $00, $00, $00, $00, $00, $00, $00
DB $F8, $08, $74, $8C, $7A, $86, $74, $8A
DB $6C, $92, $4C, $B2, $3C, $C2, $D6, $AA
DB $02, $80, $82, $02, $02, $02, $06, $02
DB $0C, $04, $1C, $04, $18, $08, $F0, $F0
DB $54, $AC, $24, $D4, $02, $FE, $52, $AA
DB $09, $77, $83, $3D, $EE, $DE, $E8, $98
DB $80, $80, $40, $40, $A0, $20, $90, $10
DB $08, $08, $44, $84, $F2, $C2, $38, $30



    
    CardBlanks: ;sections of card with just card outline - top, top-right corner, bottom, bottom-right corner
    DB $FA, $FF, $00, $00, $00, $00, $00, $00
    DB $00, $00, $00, $00, $00, $00, $00, $00
    DB $94, $EA, $01, $00, $01, $00, $00, $00
    DB $01, $00, $00, $00, $00, $00, $00, $00
    DB $00, $00, $00, $00, $00, $00, $00, $00
    DB $00, $00, $00, $00, $00, $00, $FA, $FF
    DB $00, $00, $00, $00, $00, $00, $01, $00
    DB $00, $00, $01, $00, $01, $00, $94, $EA

    


    


    
TilesEnd:


Tilemap:
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 
db BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, BLANK_TILE, 

TilemapEnd:


    