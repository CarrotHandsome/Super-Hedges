INCLUDE "hardware.inc"
INCLUDE "game.inc"


SECTION "Rendering", rom0

;tilemap $9800-$9bff, 32x32 tiles
;a=index, b=rank hl=vram location of top left corner
RenderCard::
    
    push de
    push bc
    push hl ; save vram location  

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;GET TO CARD DEFINITION;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    
    
    ld c, b ;rank
    ;get address of start of card definition
    ld h, 0
    ld l, a    
    ld b, 3 ;multiply index by 8 (size of each entry)
    call MultiplyN
    call HLtoDE
    ;point hl at the cards definition's first byte
    ld hl, CardDef 
    call Add16BitTo16Bit ;add index offset to address   
    
    call WaitNextFrame
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;DRAW RANK, TOP, AND TOP RIGHT;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;get the rank tile index
    ld a, [hli] ;this byte is RRRRRSSS
    ;isolate the suit
    and %00000111
    ld [wScratchJ], a
    
    pop de ;get the vram address   
    push hl ;hold address of first byte of card definition art tile indices
    ld a, c
    dec a
    ld [de], a ;draw the rank tile
    inc de ;move to next tile to be drawn
    ld a, NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART + NUM_MIDDLEART + NUM_RIGHTART  ;draw top of card
    ld [de], a
    inc de
    ld a, NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART + NUM_MIDDLEART + NUM_RIGHTART + 1
    ld [de], a
    ld a, 30
    ;add 30 to de (vram)
    push de
    pop hl
    call Add8BitTo16Bit
    push hl
    pop de    
    ;call HLtoDE
    ;call UnScratchHL
    pop hl ;get address of first art byte
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;DRAW UPPER ART;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;the below a is LLLLLMMM (index of left art and partial index of middle art)    
    
    ld a, [hli]
    
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
    ;call ScratchHL
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
    push hl ;address of first lower art byte
    push de
    pop hl
    call Add8BitTo16Bit
    push hl
    pop de
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;DRAW LOWER ART;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    pop hl
    ;the below a is LLLLLMMM (index of left art and partial index of middle art)    
    ld a, [hli]
    ; hl now pointing to 2nd byte of lower art
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
    ;get right art index
    and %00011111
    add NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART + NUM_MIDDLEART
    ld [de], a
    ld a, 30    
    push de
    pop hl
    call Add8BitTo16Bit
    push hl
    pop de

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;DRAW BOTTOM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ld a, [wScratchJ] ;suit
    add NUM_RANKS  
    ld [de], a
    inc de
    ld a, NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART + NUM_MIDDLEART + NUM_RIGHTART + 2
    ld [de], a
    inc de
    ld a, NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART + NUM_MIDDLEART + NUM_RIGHTART + 3
    ld [de], a

    
    pop bc
    pop de   

    call WaitNextFrame
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

;;goes through PlayerCards and renders by order each one whose location is 01
RenderHand::
    push bc
    push de
    push hl
    call WaitNextFrame
    ;get # of cards in hand
    ld hl, PlayerCards    
    ld a, $01
    call CountCards   
    ; dec hl ;offset inc hl 4 times at beginning of render loop
    ; dec hl
    ; dec hl
    ; dec hl
    ;call ScratchHL
    ld d, a ;d is card count in hand
    ld a, 0
    ld e, a ;e is cards rendered so far

    ;determine which of 3 layouts to render, 1-5 cards, 6-8 cards, or 9-15 cards
    ld a, d ;get back to card count
    add 0
    jp z, .endRender ;return without rendering anything if there are 0 cards in hand
    sub 10 
    jp nc, .render15
    ld a, d
    sub 7
    jp nc, .render8
    ;set hand offset and render. 
    ld a, 3
    ld [wHandOffset], a
    jp .renderLoop

    .render8:
        ld a, 2
        ld [wHandOffset], a
        jp .renderLoop  

    .render15:
        ld a, 1
        ld [wHandOffset], a    
    .renderLoop: 
        
        
        ld hl, PlayerCards
        ;hand count is now # of cards left to render, and thus the order value of the card we want to render
        ld a, d 
        dec a ;offset for 0-based counting
        ;adjust a to GetIndexFromOrder, takes OOOOOOLL
        sla a
        sla a            
        or %00000001 ;give it the hand location code 01
        call GetIndexFromOrder
        ;now convert the index into an address
        ld b, 2
        call GetAddressFromIndex
        call .render
        ;check for end of render
        ld a, d
        cp 0
        jp nz, .renderLoop
        .endRender:
            pop hl
            pop de
            pop bc
            ret  
        
    .render:
            ld a, [hl]
            srl a
            srl a
            ld [wScratchJ], a ;save base index
            inc hl
            inc hl ;go to 3rd byte and get turn rank 
            ld a, [hl] ;load RRRrrrrr
            and %00011111
            ld [wScratchF], a ;save rank            
            
            ;add rendered card count * offset to vram address 
            ld a, [wHandOffset]
            ld b, e               
            call Multiply8            
            ld hl, HAND_CARD_1 ;add offset to vram location       
            call Add8BitTo16Bit
            ld a, [wScratchF]
            ld b, a ;load b with rank
            ;call WaitNextFrame
            ld a, [wScratchJ] ;get card index back
            
            call RenderCard  
            inc e ;rendered card count increases
            dec d ;cards to render decreases
            
            ret
        
        
    


;sets tiles in hand zone to clear.  $99C0 - $9A33
ClearHand::
    ld hl, HAND_CARD_1
    ld a, 20
    ld b, 4
    call FillBlock
    ret