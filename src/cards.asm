INCLUDE "hardware.inc"
INCLUDE "game.inc"

SECTION "Cards", rom0
;; location:
;;   00: player deck/scenario deck
;;   01: hand/encounter zone
;;   10: discard/failure stack
;;   11: removed from playfor scenario/card reward pool
;;
;;   
;;;;;;;;;;;;;;;;;;;;

;hl=card collection address(PlayerCards or ScenarioCards) a=index
;Creates card based on definition above PlayerCards in variables.asm
;returns hl as address to new card
CreateCard::
    ld c, a ;save index
    ;call ScratchHL ;save card collection address
    ;find first empty address to place the new card.
    ;need to ensure that only bytes not occupied by a card definition have $FF value
    ;eg there cant be more than cards # 0-62
    ld a, MAX_CARDS ;multiply this by 4 to get the furthest byte possible
    sla a
    sla a
    ld b, a    
    dec hl
    dec hl
    dec hl
    dec hl
    .findEmpty
        inc hl
        inc hl
        inc hl
        inc hl
        ld a, b
        dec a
        ret z ;return if max cards reached, doing nothing
        ld b, a
        ld a, [hl]        
        cp NULL_CARD
        jp nz, .findEmpty
    ;load index and rotate left to add location bits (0 0)
    ld a, c
    sla a
    sla a
    ld [hl], a ;byte representing base index and location
    push hl ;save address of new card
    ;get base definition from index
    ld hl, CardDef
    ld a, c
    ld b, 3 
    call GetAddressFromIndex ;hl now pointing at base card definition
    ld a, [hl] ;a=RRRRRSSS
    pop hl ;get new card address back
    ;isolate rank
    srl a
    srl a
    srl a
    ld c, a
    ;rotate to have only 2 leftmost bits of rank
    srl a
    srl a
    srl a
    inc hl
    ld [hli], a ;OOOOOORR
    ld a, c
    ;rotate to have last 3 rank bits on left of byte
    sla a
    sla a
    sla a
    sla a
    sla a
    or c ;full rank goes in last 5 bits of this byte
    ld [hli], a ;RRRrrrrr
    ld [hl], $00 ;placeholder byte, maybe for visual flags or card effects    
    dec hl
    dec hl
    dec hl ;end on first byte of new card
    ret

;hl=collection address(PlayerCards eg), a=location($01 for hand eg). returns a as number of cards at the location
CountCards::
    push hl
    push bc
    push de
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
        pop de
        pop bc
        pop hl        
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
    push bc
    push de
    
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
    
    pop de
    pop bc
    ret

;hl=address of collection a=OOOOOOLL
;returns a=index
GetIndexFromOrder::    
    push de
    push hl
    ;get number of cards in location
    ld d, a ;
    srl d
    srl d
    and %00000011
    ld e, a ;d holds --OOOOOO, e holds ------LL
    call CountCards
    ld b, a ;b=number of cards
    ;make sure that order value < number of cards or else end loop
    ld a, d
    cp b
    jp nc, .endLoop
    ;loop through addresses [order value] times
    ld b, 0 ;track index
    .loop:
        ld a, [hl] ;load index/location
        ;check location
        and %00000011
        cp e
        jp nz, .loopBack        
        inc hl
        ld a, [hl] ;load order/rank
        dec hl
        srl a
        srl a
        ;check order
        cp d
        jp nz, .loopBack
        ;found card, b=index
        ld a, b
        jp .endLoop
    .endLoop:
        pop hl
        pop de
        ret    
    .loopBack:
        inc b
        inc hl
        inc hl
        inc hl
        inc hl
        jp .loop
    ret



;;hl=collection address, a=iiiiiiLL/OOOOOOLL (LL=destination location) 
;b= -----LLM (LL=origin location) location and method(OOOOOO=>iiiiii or not)
;;changes last 2 bits in first byte of card data to reflect new location
;;Card is given order value of 1 + currently highest order value in the new location
;;Cards in old location whose order is higher than that of the moved card have their orders shifted down
MoveCard::        
    push de
    push hl

    ld [wScratchE], a    
    ;check b, if 0 jump to .start (0 => get address by index, 1 => by order)
    ld a, b
    and %00000001 ;get method
    jp z, .start ;if method is 0 skip converting order to index
    ;change a from OOOOOOLL to iiiiiiLL
    ld a, [wScratchE]
    and %11111100
    srl b
    ld c, b ;save original location
    or b
    call GetIndexFromOrder
    ;shift index to left of byte and add origin location code to right
    sla a
    sla a
    or c
    ld c, a
    ld a, [wScratchE]
    ld b, a
    push bc ;b=original index/order + destination LL. c=index + origin LL
    ld a, c

    .start:   
    ;first check that the card isnt already in the location
    srl a
    srl a
    ld b, 2
    call GetAddressFromIndex
    ld a, [hl]
    and %00000011
    ld b, a
    ld a, [wScratchE]
    and %00000011
    cp b
    jp nz, .canMove
    pop bc
    pop hl
    pop de    
    ret
    .canMove:
    pop bc
    pop hl
    ;check if there are 0 cards in the new location.   
    call CountCards
    cp 0
    jp z, .noCardsInLocation ;skip the order finding process if there are no other cards
    ;otherwise get new highest order of new location (just count the cards)
    ld a, b ;b contains destination LL
    and %00000011
    call CountCards
    .noCardsInLocation:
    ld [wScratchC], a ;save new order value for moved card
    ld a, c ;c contains index (original or converted from order)
    srl a
    srl a
    ld b, 2
    call GetAddressFromIndex    
    ld a, [hli]
    ld d, a ;store original base index/location
    ld a, [hl] 
    ld e, a ;store original order/rank
    ld a, [wScratchC]
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
    ld a, [wScratchE] ;reassign location, preserving index
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

    pop de
    ret

;hl=collection address.
;move highest order card in location 00 to location 01
DrawFromDeck::    
    ld a, 0 ;deck location code
    call CountCards ;gets highest order + 1
    dec a ;account for 0-based index
    sla a
    sla a
    or 1 ;add destination location
    ld b, 1 ;order method from deck for MoveCard
    call MoveCard
    ret

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
    push bc
    ld b, a
    ld c, 0 ;highest order
    .loop:
        ld a, [hl] ;get location code
        cp NULL_CARD
        jp nc, .endLoop
        and %00000011
        cp b
        jp nz, .loopBack
        inc hl
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
    pop bc
    pop hl
    ld a, c
    ret

;returns index a
GenerateRandomBaseCardIndex::
    ld b, 0
    ld a, NUM_CARDS - 1
    call RandomRange8
    ret

DrawRandomCard::
    ld hl, PlayerCards
    ld a, $00
    call CountCards
    ld b, 0
    dec a ;compensate for 0-base count
    call RandomRange8 ;gives a random order value of a card in the location
    ld hl, PlayerCards
    sla a
    sla a
    or %00000001 ;hand location code
    ld b, %00000001 ; -----LLM: deck location and convert from order method
    call MoveCard
    ret

;make sure to order the cards. they will start with the deck (00) location code
GenerateRandomDecks::
    ld a, 63  ;number of cards to make
    ld b, 0     ;order
    
    .loop:        
        ld [wScratchG], a 
        ld a, b
        ld  [wScratchH], a
        call GenerateRandomBaseCardIndex
        ld hl, PlayerCards        
        call CreateCard   
        inc hl
        ld a, [wScratchH]
        ld b, a
        ld a, [hl]
        ;clear order bits
        and %00000011   
        ;rotate new order bits to left of byte     
        sla b
        sla b
        or b ;combine order bits with 1st 2 rank bits
        ld [hl], a        
        ld a, [wScratchH]
        ld b, a
        ld a, [wScratchG]
        inc b        
        dec a    
        jp nz, .loop
    
    ld a, 63  ;number of cards to make
    ld b, 0     ;order
    
    .loop2:        
        ld [wScratchG], a 
        ld a, b
        ld  [wScratchH], a
        call GenerateRandomBaseCardIndex
        ld hl, ScenarioCards        
        call CreateCard   
        inc hl
        ld a, [wScratchH]
        ld b, a
        ld a, [hl]
        ;clear order bits
        and %00000011   
        ;rotate new order bits to left of byte     
        sla b
        sla b
        or b ;combine order bits with 1st 2 rank bits
        ld [hl], a        
        ld a, [wScratchH]
        ld b, a
        ld a, [wScratchG]
        inc b        
        dec a    
        jp nz, .loop2
    ret

;hl=collection address, a=card index, b: 3=>reset to base rank, 2=>reset to scenario rank
ResetRank::
    
    ld c, b
    ld b, 2
    call GetAddressFromIndex
    push hl
    ld a, c
    xor 3 ;will be 0 iff a==3
    jp z, .setToBase
    inc hl
    ld a, [hl]
    and %00000011
    sla a
    sla a
    sla a
    ld b, a
    inc hl
    ld a, [hl]
    srl a
    srl a
    srl a
    srl a
    srl a
    or b; a=scenario rank    
    jp .resetRank
    .setToBase:
    ld a, [hl]
    srl a
    srl a
    ld hl, CardDef
    ld b, 3
    call GetAddressFromIndex
    ld a, [hl]
    srl a
    srl a
    srl a ;a=base rank

    .resetRank  
    pop hl
    ld c, a
    ;get leftmost 2 bits of rank bits in byte ---rrrrr for byte OOOOOORR
    srl a
    srl a
    srl a 
    ld b, a ;=000000rr
    ld a, c
    and %00000111
    sla a
    sla a
    sla a
    ld d, a ;=rrr00000
    inc hl 
    ld a, [hl] ;OOOOOORR
    and %11111100
    or b
    ld [hl], a
    inc hl
    ld a, [hl]
    ld a, d
    or c ;=rrrRRRRR
    ld [hl], a
    
    ret

;hl=collection address, a=index, b=RRRRRTTT R=rank T=tier of rank: base rank > scenario rank > turn rank
;this only needs scenario or turn rank - base rank cant be altered. altering one doesnt alter the other
;TT: 000 => scenario, 001 => turn
SetRank::
    push bc
    push hl
    ld c, b
    ld d, c
    srl c
    srl c
    srl c ;=rank
    ld b, 2
    call GetAddressFromIndex
    ld a, d
    and %00000011
    cp 0
    jp z, .scenario
    ;if not scenario rank, then edit turn rank
    inc hl
    inc hl
    ld a, [hl]
    and %11100000
    or c
    ld [hl], a
    pop hl
    pop bc
    ret
    .scenario:
        inc hl
        ;edit 1st rank byte
        ld a, [hl]
        and %11111100
        ld b, a
        ld a, c
        srl a
        srl a
        srl a
        or b
        ld [hli], a
        ld a, c
        and %00011111
        ld b, a
        ld a, c
        sla a
        sla a
        sla a
        sla a
        sla a
        or b
        ld [hl], a
        pop hl
        pop bc
        ret

;hl=collection address, a=TTiiiiii TT=scenario or turn rank. 00 scenario, 01 turn
GetRank::
    push bc
    push hl
    ld b, a
    and %11000000
    ld c, a ;c=TT00000
    ld a, b
    and %00111111

    ld b, 2
    call GetAddressFromIndex
    ld a, c
    and %01000000
    jp z, .scenario
    inc hl
    inc hl
    ld a, [hl]
    and %00111111
    pop hl
    pop bc
    ret
    .scenario:
        inc hl
        ld a, [hli]
        and %00000011
        sla a
        sla a
        sla a
        ld b, a
        ld a, [hl]
        and %11100000
        srl a
        srl a
        srl a
        srl a
        srl a
        or b
        pop hl
        pop bc
        ret

    
;edit players cards turn rank to +1
EditAllRanks::
    ld b, 10 ;number of cards to alter
    
    ld c, 0 ;cards altered, use for index
    .loop:
        ld hl, PlayerCards
        ld a, c
        or %01000000
        call GetRank

        ;set rank to rank+1
        inc a
        ld hl, PlayerCards
        sla a
        sla a
        sla a
        or %00000001 ;add turn rank flag
        ld b, a
        ld a, c
        call SetRank
        inc c
        ld a, b
        cp c
        jp nc, .loop
        ret




  