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
wSelectedTileIndex:: db
wHandOffset:: db


SECTION "Input Variables", wram0
wCurKeys:: db
wNewKeys:: db

SECTION "Card Locations", wram0
LocationsStart::
SelectedCard:: ds 1 
PlayerDeck:: ds 64 
PlayerDiscard:: ds 64
GameDeck:: ds 32
PlayerHand:: ds 20
LocationsEnd::
PlayerDeckPointer:: ds 2 ;16 bit address points to card on top of PlayerDeck


SECTION "Card Definitions", rom0
;;each card is defined by 8 bytes
CardDef::
db $00 ;index 0, we could have 2 extra bits here
db $80 ;first 5 bits rank, last 3 suit (snail cricket bee spider moth, 3 other options? 3 types of victory card?) rank 16 suit 0
db $10, $42 ;tleft, tmiddle, tright art indices. 1st 5 bits for left, last and first 3 bits for middle, last 5 for right
db $30, $C6 ;bleft, bmiddle, bright art indices
db $00, $00 ;effect pointer, effect parameter (or 2 effect parameters and effect pointers are based on card index number)

db $04 ;index 01 with 2 extra 0 bits at the end
db $39 ;rank 7 suit 1
db $08, $21
db $28, $A5
db $00, $00

db $08
db $1A ;rank 3 suit 2
db $00, $00
db $20, $84
db $00, $00

db $0C
db $0B ;rank 1 suit 3
db $18, $63
db $38, $E7
db $00, $00

db $10 
db $A4 ;rank 20 suit 4
db $08, $21
db $28, $A5
db $00, $00