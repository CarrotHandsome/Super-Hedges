INCLUDE "hardware.inc"
INCLUDE "game.inc"
SECTION "Utilities", rom0

; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
Memcopy::
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, Memcopy
    ret

;hl + de, return hl
Add16BitTo16Bit::
    ld a, l
    add e
    jp nc, NoCarry16
    inc h
    NoCarry16:
    ld l, a
    ld a, h
    add d
    ld h, a
    ret

;Multiply hl by 2, b times
MultiplyN::    
    MultLoop:
    call Rotate16Bit
    dec b
    jp nz, MultiplyN
    ret

;rotate hl left
Rotate16Bit::    
    ld a, l
    rla
    ld l, a
    jp nc, ReturnRotated    
    ld a, h
    rla    
    or $01
    ld h, a
    ReturnRotated:
    ret

;hl, a operands, hl returns   
Add8BitTo16Bit:: 
    add l
    jp nc, NoCarry
    inc h
    NoCarry:
    ld l, a
    ret

SECTION "GlobalVariables", wram0
wFrameCounter:: db
wTilemapAddress:: dw
wScratchA:: db
wScratchB:: db
wSelectedTileIndex:: db

SECTION "Input Variables", WRAM0
wCurKeys:: db
wNewKeys:: db