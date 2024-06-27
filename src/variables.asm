INCLUDE "hardware.inc"


SECTION "GlobalVariables", wram0
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
db $00, $09 ;index 0, suit 0, rank 10. index $ff would indicate no card
db $00, $20 ;tleft, tmiddle, tright art indices. 1st 5 bits for left, last and first 3 bits for middle, last 5 for right
db $00, $20
db $00, $00

db $01, $18
db $00, $40
db $00, $40
db $00, $00