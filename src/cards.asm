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
    ld a, [hli]
    sub NULL_CARD
    jp nc, .returnZero 
    ld b, 0
    .loopTillEmpty
        inc b
        ld a, [hli]
        sub NULL_CARD
        jp c, .loopTillEmpty    
    ld a, b
    ret 
    .returnZero
        ld a, 0
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
    ret
