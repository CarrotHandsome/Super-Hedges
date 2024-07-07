INCLUDE "hardware.inc"
INCLUDE "game.inc"

SECTION "Cards", rom0
;a=index, hl=card location (GameDeck, PlayerDiscard, etc)
CreateCard::
    ld b, a
    .findEmpty
        ld a, [hli]
        sub NULL_CARD
        jp c, .findEmpty
    dec hl
    ld [hl], b
    ret

;hl=location, returns a as number of cards at the card location starting at hl
;assumes no gaps between cards and all cards are at the beginning of the memory reserved for the location
CountCards::
    ld b, 0
    ld a, [hli]
    sub NULL_CARD
    jp nc, .returnCount 
    .loopTillEmpty
        inc b
        ld a, MAX_CARDS_HAND
        sub b
        jp z, .returnCount
        ld a, [hli]
        sub NULL_CARD
        jp c, .loopTillEmpty    
    .returnCount:
        ld a, b
        ret

;Sets all card locations to $FF
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
        ;initialize player deck pointer
        ld hl, PlayerDeckPointer
        call HLtoDE
        ld hl, PlayerDeck
        ld a, h
        ld [de], a
        inc de
        ld a, l
        ld [de], a        
    ret

    ;returns index a
GenerateRandomCard::
    ld b, 0
    ld a, NUM_CARDS - 1
    call RandomRange8
    sla a ; two 0 bits on the right end
    sla a
    ret

GenerateRandomDeck::
    ld c, 64
    .loop:
        call GenerateRandomCard
        ld hl, PlayerDeck
        call CreateCard
        dec c
        ld a, c
        sub 0
        jp nz, .loop
    ret