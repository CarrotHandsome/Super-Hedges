INCLUDE "hardware.inc"
INCLUDE "game.inc"

SECTION "Utilities", rom0

; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
;does not preserve a

JustReturn::
    ret
Memcopy::
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, Memcopy
    ret

;divides a by b, returns a as product, b as remainder
Divide::
    ld c, 0 ;product
    ld d, 0 ;remainder
    DivLoop:
        ld d, a
        inc c
        sub b        
        jp nc, DivLoop
        ld b, d
        dec c
        ld a, c
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
    call SL16Bit
    dec b
    jp nz, MultiplyN
    ret

;rotate hl left. does not preserve a
SL16Bit::      
    sla h
    sla l
    ret nc
    ld a, h
    or $01
    ld h, a
    ret
;rotate hl right. 
SR16Bit::
    srl l
    srl h
    ret nc
    ld a, l
    or $80
    ld l, a
    ret

;takes hl and de, returns hl
XOR16Bit::
    ld a, h
    ld b, d
    xor b
    ld h, a
    ld a, l
    ld b, e
    xor b
    ld l, a
    ret
;takes [wRandom] as seed
Random::
    ld a, [wRandom]
    ld h, a
    ld a, [wRandom + 1]
    ld l, a
    call HLtoDE
    call SL16Bit
    call SL16Bit
    call SL16Bit
    call SL16Bit
    call SL16Bit
    call SL16Bit
    call SL16Bit
    call XOR16Bit
    call HLtoDE
    call SR16Bit
    call SR16Bit
    call SR16Bit
    call SR16Bit
    call SR16Bit
    call SR16Bit
    call SR16Bit
    call SR16Bit
    call SR16Bit
    call XOR16Bit
    call HLtoDE
    call SL16Bit
    call SL16Bit
    call SL16Bit
    call SL16Bit
    call SL16Bit
    call SL16Bit
    call SL16Bit
    call SL16Bit
    call XOR16Bit
    ld a, h
    ld [wRandom], a
    ld a, l
    ld [wRandom + 1], a
    ret

;takes b, a as min, max, returns a as range bound random 8bit number
RandomRange8::
    sub b
    add 1
    ld [wScratchB], a ;preserve n

    ld a, b
    ld [wScratchA], a ;preserve min
    ld a, [wScratchB]
    ld b, a
    ld a, 255
    call Divide ;b is remainder now
    ld a, b
    ld [wScratchC], a ;preserve remainder
    RejectionLoop: ;loop until rand + remainder - 255 >= 0
        call Random        
        ld a, [wScratchC]
        ld b, a
        ld a, [wRandom + 1]
        add b
        sub 255
        jp nc, RejectionLoop
    ;return min + random % n
    ld a, [wScratchB]
    ld b, a
    ld a, [wRandom + 1]
    call Divide
    ld a, [wScratchA]
    ld d, a
    ld a, b
    add d    
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