INCLUDE "hardware.inc"
INCLUDE "game.inc"


SECTION "Drawing", rom0

;tilemap $9800-$9bff, 32x32 tiles
;a=index, hl=vram location of top left corner
DrawCard::
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;GET TO CARD DEFINITION;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    ld [wScratchE], a ;preserve those 2 bits for later  
    srl a 
    srl a
    call HLtoDE
    call ScratchDE ; scratches c,e hold vram location    
    ld h, 0
    ld l, a
    ld b, 3 ;multiply index by 8 (size of each entry)
    call MultiplyN
    call HLtoDE
    ld hl, CardDef
    call Add16BitTo16Bit ;add index offset to address    
    inc hl
    
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;DRAW RANK, TOP, AND TOP RIGHT;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;get the rank tile index
    ld a, [hli] ;this byte is RRRRRRSS
    ld [wScratchF], a
    ;isolate the rank   
    srl a
    srl a   
    dec a
    call ScratchHL ;scratches a,b hold address of first byte of card definition art tile indices
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
    ;;;;;;DRAW BOTTOM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ld a, [wScratchF]
    and %00000011  ;isolate suit
    add NUM_RANKS  ;skip over rank and top tiles
    ld [de], a
    inc de
    ld a, NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART + NUM_MIDDLEART + NUM_RIGHTART + 2
    ld [de], a
    inc de
    ld a, NUM_RANKS + NUM_SUITS + NUM_ANIMALS + NUM_LEFTART + NUM_MIDDLEART + NUM_RIGHTART + 3
    ld [de], a
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
    
    ld de, $9800
    call Add16BitTo16Bit ;hl is now start point in tilemap    
    ld a, [wSelectedTileIndex]
    ld e, a
    ld d, c
    OuterLoop:
        ld b, c
        ld a, e
        InnerLoop:
            ld [hli], a  ;2 cycles           
            dec b        ;1 cycle
            jp nz, InnerLoop ;3 cycles
        ld a, 32
        sub c
        call Add8BitTo16Bit
        dec d
        jp nz, OuterLoop
    ret

;call FillBlock on whole screen
ClearBG1::
    ld a, $9
    ld [wSelectedTileIndex], a
    ld a, 0
    ld b, 0
    ld c, 20
    call FillBlock
    ret