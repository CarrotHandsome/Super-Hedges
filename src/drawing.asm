INCLUDE "hardware.inc"
INCLUDE "game.inc"


SECTION "Drawing", rom0

ClearBG1::
    ld hl, $9800
    ld de, 1024
    ClearLoop:  
        ld [hl], TL_GRS
        inc hl
        dec de
        ld a, d
        or e
        jp nz, ClearLoop
    ret

DrawCard::
    ;tilemap $9800-$9bff, 32x32 tiles
    ;a=x pos, b=ypos
    ;get 32 * b + a
    ld d, a
    ld h, 0
    ld l, b
    ld b, 5 ;multiply by 2 5 times to get x32
    call MultiplyN ;takes hl, b
    ld a, d
    call Add8BitTo16Bit ;takes hl, a
    ;add $9800 to hl
    ld de, $9800
    call Add16BitTo16Bit
    
    ld [hl], CD_TL_
    inc hl
    ld [hl], CD_TT_
    inc hl
    ld [hl], CD_TR_
    ld a, 30
    call Add8BitTo16Bit
    ld [hl], CD_LL_
    inc hl
    ld [hl], CD_MM_
    inc hl
    ld [hl], CD_RR_
    ld a, 30
    call Add8BitTo16Bit
    ld [hl], CD_LL_
    inc hl
    ld [hl], CD_MM_
    inc hl
    ld [hl], CD_RR_
    ld a, 30
    call Add8BitTo16Bit
    ld [hl], CD_BL_
    inc hl
    ld [hl], CD_BB_
    inc hl
    ld [hl], CD_BR_
    ret

;a = ypos, b = xpos, c = length, wSelectedTileIndex
;make sure the address and length dont cause an attempt to write outside tilemap memory
FillBlock::
    ;get 16 bit start offset = a * 32 + b
    ld d, a
    ld e, b    
    ld h, 0
    ld l, a
    ld b, 5
    call MultiplyN
    ld a, e
    call Add8BitTo16Bit
    ld a, c
    ld [wScratchA], a
    ld de, $9800
    call Add16BitTo16Bit ;hl is now start point in tilemap
    ld a, [wScratchA]
    ld c, a
    ld d, c
    OuterLoop:
        ld b, c
        InnerLoop:
            ld a, [wSelectedTileIndex]
            ld [hl], a
            inc hl
            dec b
            jp nz, InnerLoop
        ld a, 32
        sub c
        call Add8BitTo16Bit
        dec d
        jp nz, OuterLoop
    ret