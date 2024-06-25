INCLUDE "hardware.inc"
INCLUDE "game.inc"

SECTION "Header", ROM0[$100]
    jp EntryPoint

    ds $150 - @, 0; make room for header

EntryPoint:
;do not turn off LCD outside VBlank
WaitVBlank:
ld a, [rLY]
cp 144
jp c, WaitVBlank

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

;copy tile data
ld de, Paddle
ld hl, $8000
ld bc, PaddleEnd - Paddle
call Memcopy

;Draw a card
ld hl, $9800 ;start of tilemap memory
ld a, 10
ld b, a
ld a, 11
call DrawCard
ld a, 12
ld b, a
ld a, 13
call DrawCard
ld a, 11
ld b, a
ld a, 9
call DrawCard
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
ld a, TL_GRS
ld [wSelectedTileIndex], a

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

CheckA:
    ld a, [wCurKeys]
    and a, PADF_A
    jp z, CheckLeft
PressA:  
  ld a, 10
  ld b, 11
  ld c, 3
  call FillBlock

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






Tiles:
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33322222
    dw `33322222
    dw `33322222
    dw `33322211
    dw `33322211
    dw `33333333
    dw `33333333
    dw `33333333
    dw `22222222
    dw `22222222
    dw `22222222
    dw `11111111
    dw `11111111
    dw `33333333
    dw `33333333
    dw `33333333
    dw `22222333
    dw `22222333
    dw `22222333
    dw `11222333
    dw `11222333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33322211
    dw `33322211
    dw `33322211
    dw `33322211
    dw `33322211
    dw `33322211
    dw `33322211
    dw `33322211
    dw `22222222
    dw `20000000
    dw `20111111
    dw `20111111
    dw `20111111
    dw `20111111
    dw `22222222
    dw `33333333
    dw `22222223
    dw `00000023
    dw `11111123
    dw `11111123
    dw `11111123
    dw `11111123
    dw `22222223
    dw `33333333
    dw `11222333
    dw `11222333
    dw `11222333
    dw `11222333
    dw `11222333
    dw `11222333
    dw `11222333
    dw `11222333
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `11001100
    dw `11111111
    dw `11111111
    dw `21212121
    dw `22222222
    dw `22322232
    dw `23232323
    dw `33333333
    ;card tiles
    ; card top left corner
    DB $00,$7F,$00,$80,$2E,$AE,$2A,$AA
    DB $2A,$AA,$2A,$AA,$2E,$AE,$00,$80
    ;card top right corner
    DB $00,$FE,$10,$11,$38,$39,$7C,$7D
    DB $7C,$7D,$38,$39,$54,$55,$38,$39
    ;card bottom right corner
    DB $00,$01,$00,$01,$00,$01,$00,$01
    DB $00,$01,$00,$01,$00,$01,$00,$FE
    ;card bottom left corner
    DB $00,$80,$00,$80,$00,$80,$00,$80
    DB $00,$80,$00,$80,$00,$80,$00,$7F
    ;left side
    DB $00,$80,$00,$80,$00,$80,$00,$80
    DB $00,$80,$00,$80,$00,$80,$00,$80    
    ; card top
    DB $00,$FF,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00    
    ;card right side
    DB $00,$01,$00,$01,$00,$01,$00,$01
    DB $00,$01,$00,$01,$00,$01,$00,$01
    ;card bottom
    DB $00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$FF
    ; card middle
    DB $00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00    
    ; grass
    DB $42,$84,$11,$22,$08,$11,$04,$48
    DB $00,$24,$00,$10,$01,$4A,$00,$21
    ; Paste your logo here:
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222211
    dw `22222211
    dw `22222211
    dw `22222222
    dw `22222222
    dw `22222222
    dw `11111111
    dw `11111111
    dw `11221111
    dw `11221111
    dw `11000011
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `11222222
    dw `11222222
    dw `11222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222211
    dw `22222200
    dw `22222200
    dw `22000000
    dw `22000000
    dw `22222222
    dw `22222222
    dw `22222222
    dw `11000011
    dw `11111111
    dw `11111111
    dw `11111111
    dw `11111111
    dw `11111111
    dw `11111111
    dw `11000022
    dw `11222222
    dw `11222222
    dw `11222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222200
    dw `22222200
    dw `22222211
    dw `22222211
    dw `22221111
    dw `22221111
    dw `22221111
    dw `11000022
    dw `00112222
    dw `00112222
    dw `11112200
    dw `11112200
    dw `11220000
    dw `11220000
    dw `11220000
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22000000
    dw `22000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `11110022
    dw `11110022
    dw `11110022
    dw `22221111
    dw `22221111
    dw `22221111
    dw `22221111
    dw `22221111
    dw `22222211
    dw `22222211
    dw `22222222
    dw `11220000
    dw `11110000
    dw `11110000
    dw `11111111
    dw `11111111
    dw `11111111
    dw `11111111
    dw `22222222
    dw `00000000
    dw `00111111
    dw `00111111
    dw `11111111
    dw `11111111
    dw `11111111
    dw `11111111
    dw `22222222
    dw `11110022
    dw `11000022
    dw `11000022
    dw `00002222
    dw `00002222
    dw `00222222
    dw `00222222
    dw `22222222    
    
    
TilesEnd:

Paddle:
    dw `13333331
    dw `30000003
    dw `13333331
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
PaddleEnd:

Tilemap:
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0
db $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12,  0,0,0,0,0,0,0,0,0,0,0,0

TilemapEnd:


    