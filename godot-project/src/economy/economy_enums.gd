## EconomyEnums — the print-rarity axis for dropped card instances (Phase 3, M3).
##
## This is the NEW rolled rarity (design decision D7): rarity is a ROLL AT DROP
## TIME, not derived from HSK level or SRS stability. Every drop rolls
## common→epic with a nonzero floor for every launch-active tier from drop #1,
## weighted upward by clutch recall / depth / streak (see RarityRoll). Rarity
## sets craft value and the grade-band CEILING (see GradeBand) — NOT base power,
## NOT the ability family.
##
## Deliberately distinct from two existing "rarity"-shaped enums:
##   - SrsEnums.LootRarity (COMMON/LEARNING/ABOUT_TO_FORGET/NEW_CARD) — the
##     SRS-state read; "COMMON" is now the silent default, not a headline.
##   - CollectionEnums.CardTier (the retired SRS-derived gem tiers).
## This enum is the TCG *print rarity* half of "card = rarity × grade".
class_name EconomyEnums
extends RefCounted

enum Rarity { COMMON, UNCOMMON, RARE, EPIC }

## Launch ships common→rare; the EPIC tier arrives with the HSK-4 stretch scope
## (a rarer ROLL, not an HSK4 character). RarityRoll keeps epic at zero weight
## until then — the enum value exists now so saves and the grade-cap table are
## already epic-ready.
const LAUNCH_MAX_RARITY := Rarity.RARE


static func rarity_name(r: int) -> String:
	match r:
		Rarity.COMMON: return "Common"
		Rarity.UNCOMMON: return "Uncommon"
		Rarity.RARE: return "Rare"
		Rarity.EPIC: return "Epic"
	return "Common"


## Single-letter tag for compact UI (haul rows, triage list).
static func rarity_initial(r: int) -> String:
	match r:
		Rarity.COMMON: return "C"
		Rarity.UNCOMMON: return "U"
		Rarity.RARE: return "R"
		Rarity.EPIC: return "E"
	return "C"


static func rarity_color(r: int) -> Color:
	match r:
		Rarity.COMMON: return Color(0.72, 0.72, 0.74)    # neutral gray
		Rarity.UNCOMMON: return Color(0.36, 0.78, 0.42)   # green
		Rarity.RARE: return Color(0.32, 0.56, 0.95)       # blue
		Rarity.EPIC: return Color(0.66, 0.38, 0.92)       # purple
	return Color(0.72, 0.72, 0.74)


## Sort/compare rank — higher rarity = higher number (keep-first at triage).
static func rarity_rank(r: int) -> int:
	return int(r)


static func all_rarities() -> Array:
	return [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE, Rarity.EPIC]


## The rarities that can actually roll at launch (epic excluded until the
## HSK-4 stretch lifts the ceiling).
static func launch_rarities() -> Array:
	var out: Array = []
	for r in all_rarities():
		if int(r) <= int(LAUNCH_MAX_RARITY):
			out.append(r)
	return out
