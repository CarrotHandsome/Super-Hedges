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
    ;make new card index number. first get number of bytes into definitions section, 
    ;then divide by 4 to account for byte length of each definition
    ; inc b
    ; ld a, MAX_CARDS
    ; sub b ;number of bytes into section
    ; srl a
    ; srl a ;divided by 4
    ; ld [wScratchJ], a ;new card index number
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
    ld [hl], $00 ;placeholder byte, maybe for 








    ;and %11111100 ;remove extra bits
    ; srl a
    ; srl a
    ; srl a
    ; ld [wScratchI], a
    ;; ;get rank
    ; ld a, [hl] ;rank is first 5 bits of this byte 
    ; srl a
    ; srl a
    ; srl a
    ; ld [wScratchH], a ;rank
    ; ;get new card index in b
    ; ld a, [wScratchJ]
    ;;rotate so first 2 of 6 digit index is last 2 of card definition byte
    ; ld c, a
    ; srl a
    ; srl a
    ; srl a
    ; srl a
    ; ld b, a

    ; ld a, [wScratchI]
    ; or b ;a should now = IIIIIIii, ie 6 bit base index + first 2 bits of instance index
    ; call UnScratchDE
    ; call DEtoHL ;hl is now new card address
    ; ld [hli], a ;load first compound index byte into new card address
    ; call ScratchHL
    ; ;for next byte get remaining 4 bits of instance index for the first 4 bits of next byte, and first 4 bits of scenario rank (defaults to base rank)
    ; ld a, [wScratchJ]
    ; sla a
    ; sla a
    ; sla a
    ; sla a
    ; ld b, a
    ; ld a, [wScratchH]
    ; srl a ;only 4 bits left in the byte - last bit of rank is in next byte
    ; or b
    ; ld [hli], a ;second compound byte - 2nd half of instance index and first 4 bits of scenario rank
    ; ;get last bit of scenario rank and append all 5 bits of rank to that, then finally make the last 2 bits 00 to correspond to the deck location
    ; ld a, [wScratchH]
    ; sla a
    ; sla a
    ; sla a
    ; sla a
    ; sla a
    ; sla a
    ; sla a
    ; ld b, a
    ; ld a, [wScratchH]
    ; sla a
    ; sla a
    ; or b
    ; and %11111100
    ; ld [hli], a
    ; ld [hl], $00 ;placeholder byte for card effect variables or something else

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
MoveCardIntra::
    ;will need to check if card being moved has top of deck pointer/adjust order
    ld [wScratchE], a ;save location
    srl a
    srl a
    ld b, 2
    call GetAddressFromIndex
    ld a, [hl]
    and %11111100
    ld b, a
    ld a, [wScratchE]
    and %00000011
    or b
    ld [hl], a
    ret

;move first card in deck to hand
PlayerDraw::
    ;get index of first card in deck
    ;go through PlayerCards, test for being in the deck and for order of 0
    ld hl, PlayerCards
    call HLtoDE ;cached address
    .loop:
        ;test location
        ;call DEtoHL
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

;returns index a
GenerateRandomBaseCardIndex::
    ld b, 0
    ld a, NUM_CARDS - 1
    call RandomRange8
    ret

GenerateRandomDeck::
    ld a, 63    
    .loop:
        ld [wScratchG], a
        call GenerateRandomBaseCardIndex
        ld hl, PlayerCards        
        call CreateCard
        ld a, [wScratchG]
        dec a
        jp nz, .loop
    ret