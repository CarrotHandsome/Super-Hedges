INCLUDE "hardware.inc"


SECTION "GlobalVariables", wram0
wRandom:: dw
wFrameCounter:: db
wTilemapAddress:: dw
wScratchA:: db
wScratchB:: db
wScratchC:: db
wScratchD:: db
wScratchE:: db
wScratchF:: db
wScratchG:: db
wScratchH:: db
wScratchI:: db
wScratchJ:: db
wScratchK:: db
wScratchL:: db
wSelectedTileIndex:: db
wHandOffset:: db


SECTION "Input Variables", wram0
wCurKeys:: db
wNewKeys:: db

SECTION "Card Locations", wram0
LocationsStart::
;;;;;PLAYER CARD DEFINITION;;;;;;;;;;;;;;;
;byte 1, bits 0-5: definition index (base card definition)
;byte 1, bits 6-7: location (deck, hand, etc)
;byte 2, bits 0-4: scenario rank (resets to base card rank at end of scenario)
;byte 2, bits 5-7: unused
;byte 3, bits 0-4: turn rank (resets to scenario rank at end of turn)
;byte 3, bits 5-7: unused
PlayerCards:: ds 64 * 4 ;64 cards times 4 bytes
ScenarioCards:: ds 64 * 4
LocationsEnd::



SECTION "Card Definitions", rom0
;;each card is defined by 8 bytes
CardDef::
;0 
db $80 ;RRRRRSSS suit/rank (suts: snail cricket bee spider moth) rank 16 suit 0, hedgehog
db $10, $42 ;tleft, tmiddle, tright art indices. 1st 5 bits for left, last and first 3 bits for middle, last 5 for right
db $30, $C6 ;bleft, bmiddle, bright art indices
db $00, $00, $00;effect pointer, effect parameter (or 2 effect parameters and effect pointers are based on card index number)
;1
db $39 ;rank 7 suit 1, hare
db $08, $21
db $28, $A5
db $00, $00, $00
;2
db $43 ;rank 8 suit 3, toad
db $00, $00
db $20, $84
db $00, $00, $00
;3
db $0B ;rank 1 suit 3, finch
db $18, $63
db $38, $E7
db $00, $00, $00
;4
db $A4 ;rank 20 suit 4
db $08, $21
db $28, $A5
db $00, $00, $00