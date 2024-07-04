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
wSelectedTileIndex:: db


SECTION "Input Variables", wram0
wCurKeys:: db
wNewKeys:: db

SECTION "Card Variables", wram0
SelectedCard:: ds 1 
PlayerDeck:: ds 32 ;player deck is 32 non cards
PlayerDiscard:: ds 32
GameDeck:: ds 32
PlayerHand:: ds 15

SECTION "Card Definitions", rom0
;;each card is 8 bytes
CardDef::
db $00 ;index 0, we could have 2 extra bits here
db $80 ;first 6 bits rank, last 2 suit (hedgehog hare toad finch)
db $10, $42 ;tleft, tmiddle, tright art indices. 1st 5 bits for left, last and first 3 bits for middle, last 5 for right
db $30, $C6 ;bleft, bmiddle, bright art indices
db $00, $00 ;effect pointer, effect parameter (or 2 effect parameters and effect pointers are based on card index number)

db $04 ;index 01 with 2 extra 0 bits at the end
db $39
db $08, $21
db $28, $A5
db $00, $00

db $08
db $1F
db $00, $00
db $20, $84
db $00, $00

db $0C
db $0E
db $18, $63
db $38, $E7
db $00, $00