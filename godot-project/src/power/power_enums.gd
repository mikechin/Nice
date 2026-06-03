## PowerEnums — Base-power constants for the board-game phase.
##
## Power is **inverted** vs. SRS mastery: cards you barely know are the
## strongest on the board, cards you know cold are the weakest. This drives
## the natural risk/reward — your scariest cards are the ones you understand
## least. See planning.md "Phase 1 Draft Phase" for the rationale.
class_name PowerEnums
extends RefCounted

## Source of a power boost — used by PowerBoost to track provenance so the
## UI can show "+1 from pinyin stage" instead of an opaque total.
enum BoostSource {
	BONUS_STAGE,        ## Awarded by a correct bonus-round stage
	RADICAL_MATCHUP,    ## Phase 3 board-game advantage (placeholder)
	RIME_SYNERGY,       ## Phase 3 adjacency bonus (placeholder)
}

## Base power keyed by SrsEnums.LootRarity. Inverted curve — see file header.
const BASE_POWER: Dictionary = {
	SrsEnums.LootRarity.KNOWN: 1,            ## Mastered routine reviews — filler
	SrsEnums.LootRarity.LEARNING: 4,          ## Mid-range, still being drilled
	SrsEnums.LootRarity.ABOUT_TO_FORGET: 5,   ## Comeback cards — strong
	SrsEnums.LootRarity.NEW_CARD: 7,          ## First-time reveal — strongest
}
