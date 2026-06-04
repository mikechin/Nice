## PowerEnums — Base-power constants for the legacy Phase-1/2 board-game phase.
##
## DEPRECATED (Phase 3, M5): this inverted curve — barely-known cards are the
## strongest — was OVERTURNED by the design. Combat power now comes from what you
## EARNED (rolled rarity × PSA grade), not from poor knowledge — see InstancePower
## and the EffectEnums/EffectPalette/CombatLoadout pipeline. This table is consumed
## only by the dying HandCard → "Run Complete!" path (challenge_presenter → run_manager
## → session_data) and is slated for deletion with that loop in the post-M4 structural
## sweep. Do NOT wire new power off it; left intact only so existing saves still load.
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
