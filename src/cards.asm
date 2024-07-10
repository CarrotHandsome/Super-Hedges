INCLUDE "hardware.inc"
INCLUDE "game.inc"

SECTION "Cards", rom0
;; location:
;;   00: player deck/scenario deck
;;   01: hand/encounter zone
;;   10: discard/failure stack
;;   11: removed from playfor scenario/card reward pool
;;;;;;;;;;;;;;;;;;;;

;hl=card collection address(PlayerCards or ScenarioCards) a=index
;Creates card based on definition above PlayerCards in variables.asm
;returns hl as address to new card
CreateCard::
    ld c, a ;save index
    call ScratchHL ;save card collection address
    ;find first empty address to place the new card.
    ;need to ensure that only bytes not occupied by a card definition have $FF value
    ;eg there cant be more than cards # 0-62
    ld a, MAX_CARDS ;multiply this by 4 to get the furthest byte possible
    sla a
    sla a
    ld b, a    
    .findEmpty
        ld a, b
        dec a
        ret z ;return if max cards reached, doing nothing
        ld b, a
        ld a, [hli]
        sub NULL_CARD
        jp c, .findEmpty
    
    dec hl ;hl is now address of new card
    ;load index and rotate left to add location bits (0 0)
    ld a, c
    sla a
    sla a
    ld [hli], a ;byte representing base index and location
    call HLtoDE 
    call ScratchDE
    ;get base definition from index
    ld hl, CardDef
    ld a, c
    ld b, 3 
    call GetAddressFromIndex ;hl now pointing at base card definition
    ld a, [hl] ;a=SSSRRRRR suit/rank
    and %00011111 ;isolate rank
    ld c, a
    ;rotate to have only 2 leftmost bits of rank
    srl a
    srl a
    srl a
    call UnScratchDE
    call DEtoHL
    ld [hli], a ;byte representing order and 1st 2 bits of rank
    ld a, c
    ;rotate to have last 3 rank bits on left of byte
    sla a
    sla a
    sla a
    sla a
    sla a
    or c ;full rank goes in last 5 bits of this byte
    ld [hli], a
    ld [hl], $00 ;placeholder byte, maybe for visual flags or card effects
    dec hl
    dec hl ;end on first byte of new card
    ret

;hl=collection address(PlayerCards eg), a=location($01 for hand eg). returns a as number of cards at the location
CountCards::

    ld b, 0 ;running tally of cards in the specified location 
    ld c, a 
    .loop        
        ld a, [hl]        
        sub NULL_CARD
        jp nc, .returnCount
        ld a, [hl]
        inc hl
        inc hl
        inc hl
        inc hl
        ;isolate location
        and %00000011
        sub c
        jp z, .addToCount
        jp .loop
    .returnCount:
        ld a, b
        ret
    .addToCount:    
        inc b
        jp .loop

;Sets all card locations to NULL_CARD value
InitializeCardLocations::
    ld hl, LocationsStart
    ld bc, LocationsEnd - LocationsStart ;length of memory section to initialize
    .loop
        ld [hl], NULL_CARD
        inc hl
        dec bc
        ld a, b
        or c
        jr nz, .loop
    ret

;a=index (can be base index or instance index),
; b=multiplier(multiply by 2, b times. b=2 for instance location, b=3 for base definitions),
; hl=address of card collection(PlayerCards, ScenarioCards or CardDef) 
;returns hl=address of start of card data
GetAddressFromIndex::
    ld c, b
    call ScratchHL
    ld b, c
    ld h, 0
    ld l, a
    call MultiplyN
    call HLtoDE
    call UnScratchHL
    call Add16BitTo16Bit ;add index offset to address    
    ;[hl] = first byte of card data
    ret

;;hl=collection address, a=iiiiiiLL
;;changes last 2 bits in first byte of card data to reflect new location
;;Card is given order value of 1 + currently highest order value in the new location
;;Cards in old location have their orders shifted as necessary
MoveCardIntra::    
    
    ld [wScratchE], a ;save new location
    ;first get highest order of new location
    and %00000011
    call GetHighestOrder
    inc a
    ld [wScratchB], a ;save new order value for moved card
    ld a, [wScratchE]
    srl a
    srl a
    ld b, 2
    call GetAddressFromIndex    
    ld a, [hli]
    ld d, a ;store original base index/location
    ld a, [hl] ;hl is pointing at first byte in card data
    ld e, a ;store original order/rank
    ld a, [wScratchB]
    sla a
    sla a
    ld b, a
    ld a, e
    and %00000011
    or b
    ld [hld], a ;update card's order(keeping rank unchanged)
    ld a, d
    and %11111100 ;get original base index
    ld b, a
    ld a, [wScratchE]
    and %00000011
    or b
    ld [hl], a
    
    ;next adjust order of both locations. d=BBBBBBLL, e=OOOOOORR - original location and order of moved card
    ;call ShiftOrder with hl, a=add/remove flag (1 for remove in this case), b=original order value of removed card + original location 
    call UnScratchHL
    ld a, d
    and %00000011
    ld d, a
    ld a, e
    and %11111100
    or d
    ld b, a
    ld a, 1
    call ShiftOrder
    call UnScratchHL
    ret

;move first card in deck to hand
PlayerDraw::
    ;get index of first card in deck
    ;go through PlayerCards, test for being in the deck and for order of 0
    ld hl, PlayerCards
    call HLtoDE ;cached address
    .loop:
        ;test location
        ld a, [hl]
        and %00000011
        sub 0
        jp nz, .loopBack
        ;test order
        inc hl
        ld a, [hl]
        srl a
        srl a
        sub 0        
        jp nz, .loopBack
        ;found the card, move hl back to start of card data
        dec hl
        ;subtract PlayerCards address from hl to get index
        ;only need to use lower bytes 
        ld a, l
        ld hl, PlayerCards
        ld b, l
        sub b
        ld b, 4
        call Divide
        sla a
        sla a
        or %00000001 ;add hand location code
        call MoveCardIntra
        ret
        .loopBack:
            ;move hl up to next card and start loop again
            call DEtoHL
            inc hl
            inc hl
            inc hl
            inc hl
            call HLtoDE
            jp .loop

;takes collection address hl, 6 bit order value b with rightmost 2 bits for location 
;takes a as flag for removing or adding 
;decreases/increases(parameter a) the order value of each card in the location whose order is 
;higher than the order of the indexed card
ShiftOrder::
    ld [wScratchA], a
    ld a, b
    and %00000011
    ld c, a
    ld a, b
    and %11111100 ;dont bother shifting right - the value we are comparing to is also shifted left    
    ld b, a
    .loop:
        ld a, [hl]        
        cp NULL_CARD ;end function when null card reached
        ret nc
        and %00000011
        cp c
        jp nz, .loopBack ;return to start of loop if location doesnt match
        inc hl
        ld a, [hl]
        dec hl
        and %11111100
        inc b ;need to fail the test if orders are equal, so make a slightly bigger, but not 
        ;bigger than order values that were already bigger. the value is already shifted left so 
        ;increasing a increases the value by "less than 1"
        cp b
        jp c, .loopBack ;return to start of loop if card order isnt higher than parameter order
        ;found card with matching location and order higher than that of removed card
        srl a
        srl a
        ld b, a ;b now holds current card's order
        ;bring back add/remove flag
        ld a, [wScratchA]
        and %00000001 ;zero flag if a= %00000000 (increase), nz flag otherwise (decrease)
        jp z, .increase            
        jp .decrease            
    .success
        sla b
        sla b
        ld a, b
        or c
        inc hl
        ld [hl], a
        dec hl
        jp .loopBack
    .loopBack:
        ;failed one of the 2 tests. increase hl to the next card in the collection
        ;and resume loop
        inc hl
        inc hl
        inc hl
        inc hl     
        jp .loop   
    .increase:
        inc b
        jp .success
    .decrease:
        dec b
        jp .success
    ret

;hl=collection address
;a = location code
;returns a = highest order value in the location
GetHighestOrder::
    push hl
    ld b, a
    ld c, 0 ;highest order
    .loop:
        ld a, [hli] ;get location code
        cp NULL_CARD
        jp nc, .endLoop
        and %00000011
        cp b
        jp nz, .loopBack
        ld a, [hld]
        srl a
        srl a
        cp c
        jp nc, .updateHighest
    .loopBack:  
        inc hl
        inc hl
        inc hl
        inc hl
        jp .loop
    .updateHighest:
        ld c, a
        jp .loopBack
    .endLoop:
    pop hl
    ld a, c
    ret

;returns index a
GenerateRandomBaseCardIndex::
    ld b, 0
    ld a, NUM_CARDS - 1
    call RandomRange8
    ret

GenerateRandomDeck::
    ld a, 32    
    ld b, 0
    .loop:
        ld [wScratchG], a
        call GenerateRandomBaseCardIndex
        ld hl, PlayerCards        
        call CreateCard
        inc hl
        ld a, [hl]
        and %00000011
        sla b
        sla b
        or b
        ld [hl], a
        ld a, [wScratchG]
        inc b
        dec a
        jp nz, .loop
    ret