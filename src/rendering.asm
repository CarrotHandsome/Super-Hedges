INCLUDE "hardware.inc"
INCLUDE "game.inc"


SECTION "Rendering", rom0

;tilemap $9800-$9bff, 32x32 tiles
;[wScratchJ]=index, [wScratchF]=rank hl=vram location of top left corner
RenderCard::
    call WaitNextFrame
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;GET TO CARD DEFINITION;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    ;rotate location out of byte
    ld a, [wScratchJ]
    srl a 
    srl a

    
    call HLtoDE
    call ScratchDE ; save vram location  
    ;get address of start of card definition
    ld h, 0
    ld l, a    
    ld b, 3 ;multiply index by 8 (size of each entry)
    call MultiplyN
    call HLtoDE
    ;point hl at the cards definition's first byte
    ld hl, CardDef 
    call Add16BitTo16Bit ;add index offset to address   
    

    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;DRAW RANK, TOP, AND TOP RIGHT;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;get the rank tile index
    ld a, [hli] ;this byte is RRRRRRSS
    ; ld [wScratchF], a
    ; ;isolate the rank   
    srl a
    srl a 
    srl a  
    dec a ;compensate for 0-based index
    call ScratchHL ;hold address of first byte of card definition art tile indices
    call UnScratchDE    
    ld [de], a ;draw the rank tile
    inc de ;move to next tile to be drawn
    ld a, NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART + NUM_MIDDLEART + NUM_RIGHTART  ;draw top of card
    ld [de], a
    inc de
    ld a, NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART + NUM_MIDDLEART + NUM_RIGHTART + 1
    ld [de], a
    ld a, 30
    call DEtoHL
    call Add8BitTo16Bit
    call HLtoDE
    call UnScratchHL
    
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;DRAW UPPER ART;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;the below a is LLLLLMMM (index of left art and partial index of middle art)    
    
    ld a, [hli]
    ; hl now pointing to 2nd byte of art, a = the 1st
    ld c, a
    ;isolate leftmost 5 bits by rotating right 3 times
    srl a
    srl a
    srl a
    ;add number of tiles above
    add NUM_RANKS + NUM_SUITS + NUM_ANIMALS
    ld [de], a
    inc de    
    call ScratchDE
    ld a, c
    ;rotate left 3 times and and away leftmost 2 bits to get partial index
    sla a
    sla a
    sla a
    and %00111111
    
    ld d, a ;need to join this with the first 3 bits of the 2nd byte
    ld a, [hli] ;a = MMMRRRRR
    call ScratchHL
    ld c, a
    ;rotate right to get other partial index 
    srl a
    srl a
    srl a
    srl a
    srl a
    or d ;this is the middle art index
    ;add number of tiles above
    add NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART
    call UnScratchDE
    ld [de], a
    inc de
    ld a, c
    ;finally get right art index with an and
    and %00011111
    add NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART + NUM_MIDDLEART
    ld [de], a
    ld a, 30
    call DEtoHL
    call Add8BitTo16Bit
    call HLtoDE
    call UnScratchHL
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;DRAW LOWER ART;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;the below a is LLLLLMMM (index of left art and partial index of middle art)    
    ld a, [hli]
    ; hl now pointing to 2nd byte of art
    ld c, a
    ;isolate leftmost 5 bits by rotating right 3 times
    srl a
    srl a
    srl a
    ;add number of tiles above
    add NUM_RANKS + NUM_SUITS + NUM_ANIMALS
    ld [de], a
    inc de    
    call ScratchDE
    ld a, c
    ;rotate left 3 times and and away leftmost 2 bits to get partial index
    sla a
    sla a
    sla a
    and %00111111
    
    ld d, a ;need to join this with the first 3 bits of the 2nd byte
    ld a, [hl] ;a = MMMRRRRR
    call ScratchHL
    ld c, a
    ;rotate right to get other partial index 
    srl a
    srl a
    srl a
    srl a
    srl a
    or d ;this is the middle art index
    ;add number of tiles above
    add NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART
    call UnScratchDE
    ld [de], a
    inc de
    ld a, c
    ;finally get right art index with an and
    and %00011111
    add NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART + NUM_MIDDLEART
    ld [de], a
    ld a, 30
    call DEtoHL
    call Add8BitTo16Bit
    call HLtoDE
    call UnScratchHL
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;DRAW BOTTOM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;return hl to rank/suit byte
    dec hl
    dec hl
    dec hl
    dec hl
    ld a, [hl]
    and %00000111  ;isolate suit
    add NUM_RANKS  
    ld [de], a
    inc de
    ld a, NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART + NUM_MIDDLEART + NUM_RIGHTART + 2
    ld [de], a
    inc de
    ld a, NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART + NUM_MIDDLEART + NUM_RIGHTART + 3
    ld [de], a

    call WaitNotVBlank
    call WaitVBlank
    ret

;hl=vram address ($9800 - $9BFF), a=length, b=height, fills with [wSelectedTileIndex] 
;make sure the address and length dont cause an attempt to write outside tilemap memory
FillBlock::
    ld [wScratchC], a
    ld d, a  
    ld e, b 
    
    .outerLoop:
        call WaitNextFrame
        ld a, [wScratchC]
        .innerLoop:
            ld c, a ;save length counter
            ld a, [wSelectedTileIndex] ;load tile to vram and inc vram pointer
            ld [hl], a
            inc hl
            ld a, c ;get length counter back
            dec a
            jp z, .wrap
            jp .innerLoop
            .wrap:                
                ld a, 32 ;tile map is 32 across
                sub d ;offset by length of fill
                call Add8BitTo16Bit ;wrap to next line in tile map
                ld a, e
                dec a
                ret z
                ld e, a
                jp .outerLoop

    ret

;;goes through PlayerCards and renders each one whose location is 01
RenderHand::
    call WaitNextFrame
    ;get # of cards in hand
    ld hl, PlayerCards
    call ScratchHL
    ld a, $01
    call CountCards
    call UnScratchHL
    dec hl ;offset inc hl 4 times at beginning of render loop
    dec hl
    dec hl
    dec hl
    ;call ScratchHL
    ld [wScratchH], a ;scratchH is card count
    ld a, 0
    ld [wScratchG], a ;scratchG is cards rendered so far

    ;determine which of 3 layouts to render, 1-5 cards, 6-8 cards, or 9-15 cards
    ld a, [wScratchH] ;get back to card count
    add 0
    ret z ;return without rendering anything if there are 0 cards in hand
    sub 10 
    jp nc, .render15
    ld a, [wScratchH]
    sub 7
    jp nc, .render8
    ;set hand offset and render. 
    ld a, 3
    ld [wHandOffset], a
    jp .render

    .render8:
        ld a, 2
        ld [wHandOffset], a
        jp .render       

    .render15:
        ld a, 1
        ld [wHandOffset], a    
    .render:                
        inc hl
        inc hl
        inc hl
        inc hl
        ld a, [hl] ;get base index+location of next card in PlayerCards
        ld [wScratchJ], a ;save index
        ;test if its in hand
        and %00000011
        sub 1
        jp nz, .render
        
        ;call ScratchHL
        ;get turn rank
        inc hl
        inc hl        
        ld a, [hl]  
        and %00011111
        ld [wScratchF], a ; save rank
        
        ;store hl away until after we render this card
        ld a, h
        ld [wScratchE], a
        ld a, l
        ld [wScratchI], a
        ;add rendered card count * offset to vram address 
        ld a, [wHandOffset]
        ld b, a
        ld a, [wScratchG]        
        call Multiply8
        call ScratchHL2
        ld hl, HAND_CARD_1 ;add offset to vram location       
        call Add8BitTo16Bit
        ld a, [wScratchF]
        ld b, a ;load b with rank
        ld a, [wScratchJ] ;get card index back
        call RenderCard  
        ld a, [wScratchG]
        inc a ;rendered card count increases
        ld [wScratchG], a
        ;is cards rendered == card count? if so then ret
        ld b, a
        ld a, [wScratchH] ;get card count
        sub b 
        ret z
        ;if not then restore hl to point at the next index of cards in hand and return to the start of the loop
        ld a, [wScratchE]
        ld h, a
        ld a, [wScratchI]
        ld l, a
        call UnScratchHL2
        dec hl
        dec hl
        jp .render

; RenderHand::
;     call WaitNextFrame
    
;     ;get # of cards in hand
;     ld hl, PlayerHand
;     call CountCards
;     ;point hl at card indices in player hand
;     ld hl, PlayerHand
;     ld [wScratchH], a ;scratchH is card count
;     ld a, 0
;     ld [wScratchG], a ;scratchG is cards rendered so far
;     ;determine which of 3 layouts to render, 1-5 cards, 6-8 cards, or 9-15 cards
;     ld a, [wScratchH] ;get back to card count
;     add 0
;     ret z ;return without rendering anything if there are 0 cards in hand
;     sub 10 
;     jp nc, .render15
;     ld a, [wScratchH]
;     sub 7
;     jp nc, .render8
;     ;set hand offset and render. 
;     ld a, 3
;     ld [wHandOffset], a
;     jp .render  

;     .render8:
;         ld a, 2
;         ld [wHandOffset], a
;         jp .render       

;     .render15:
;         ld a, 1
;         ld [wHandOffset], a    

;     .render:
;         ld a, [hli] ;get index of next card in hand
;         ld [wScratchJ], a ;save index
;         ;store hl away until after we render this card
;         ld a, h
;         ld [wScratchE], a
;         ld a, l
;         ld [wScratchI], a
;         ;add rendered card count * offset to vram address 
;         ld a, [wHandOffset]
;         ld b, a
;         ld a, [wScratchG]        
;         call Multiply8
;         ld hl, HAND_CARD_1 ;add offset to vram location
;         call Add8BitTo16Bit
;         ld a, [wScratchJ] ;get card index back
;         call RenderCard  
;         ld a, [wScratchG]      
;         inc a ;rendered card count increases
;         ld [wScratchG], a
;         ;is cards rendered == card count? if so then ret
;         ld b, a
;         ld a, [wScratchH] ;get card count
;         sub b 
;         ret z
;         ;if not then restore hl to point at the next index of cards in hand and return to the start of the loop
;         ld a, [wScratchE]
;         ld h, a
;         ld a, [wScratchI]
;         ld l, a
;         jp .render

;sets tiles in hand zone to clear.  $99C0 - $9A33
ClearHand::
    ld hl, HAND_CARD_1
    ld a, 20
    ld b, 4
    call FillBlock
    ret