INCLUDE "hardware.inc"
INCLUDE "game.inc"

SECTION "Utilities", rom0

; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
;does not preserve a
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
    ld b, a
    ld a, l
    add e
    jp nc, NoCarry16
    inc h
    NoCarry16:
    ld l, a
    ld a, h
    add d
    ld h, a
    ld a, b
    ret
;Multiply hl by 2, b times
MultiplyN::    
    MultLoop:
    call Rotate16Bit
    dec b
    jp nz, MultiplyN
    ret
;rotate hl left. does not preserve a
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
    ld b, a
    add l
    jp nc, NoCarry
    inc h
    NoCarry:
    ld l, a
    ld a, b
    ret

;register and memory management
ScratchHL::
    ld b, a
    ld a, h
    ld [wScratchA], a
    ld a, l
    ld [wScratchB], a
    ld a, b
    ret
UnScratchHL::
    ld b, a
    ld a, [wScratchA]
    ld h, a
    ld a, [wScratchB]
    ld l, a
    ld a, b
    ret
ScratchDE::
    ld b, a
    ld a, d
    ld [wScratchC], a
    ld a, e
    ld [wScratchD], a
    ld a, b
    ret 
UnScratchDE::
    ld b, a
    ld a, [wScratchC]
    ld d, a
    ld a, [wScratchD]
    ld e, a
    ld a, b
    ret
HLtoDE::
    ld b, a
    ld a, h
    ld d, a
    ld a, l
    ld e, a
    ld a, b
    ret
DEtoHL::
    ld b, a
    ld a, d
    ld h, a
    ld a, e
    ld l, a
    ld a, b
    ret