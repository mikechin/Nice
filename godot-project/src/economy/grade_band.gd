## GradeBand — the PSA-grade axis and its two-cap math (Phase 3, M3).
##
## A card is "rarity × grade" (TCG print rarity × condition). This file owns the
## GRADE half: the scale (0 = raw/ungraded, PSA 1–10 once crafted) and the rule
## that every instance has TWO independent ceilings on how high it can be graded:
##   - the rolled rarity sets the ceiling   → rarity_cap()
##   - the player's mastery sets the reach   → mastery_cap()
## and the achievable top grade is the lower of the two → ceiling().
##
## So PSA 10 is doubly earned: it needs a RARE-rolled instance (luck) AND deep
## mastery of the character (learning). A beginner's carrot is their best-PSA
## ceiling climbing as their stability grows. The grading *craft* (town match-3)
## is M4; this is the pure cap math it — and the binder's best-PSA record — build on.
class_name GradeBand
extends RefCounted

const RAW := 0          # ungraded — how every instance drops in the dungeon
const MIN_PSA := 1
const MAX_PSA := 10

## Rolled rarity → the highest PSA that rarity can ever reach. PSA 10 requires a
## rare (or epic) roll; commons/uncommons top out lower no matter the mastery.
const RARITY_GRADE_CAP := {
	EconomyEnums.Rarity.COMMON: 8,
	EconomyEnums.Rarity.UNCOMMON: 9,
	EconomyEnums.Rarity.RARE: 10,
	EconomyEnums.Rarity.EPIC: 10,
}

## Max stability (across challenge types) → the highest PSA mastery permits.
## Bands are ascending; the deepest band is the only one that reaches PSA 10, so
## high grades are mastery-earned. Mirrors the SRS tier stability thresholds.
const MASTERY_BANDS := [
	{ "min_stability": 0.0, "cap": 4 },
	{ "min_stability": 7.0, "cap": 6 },
	{ "min_stability": 30.0, "cap": 8 },
	{ "min_stability": 90.0, "cap": 9 },
	{ "min_stability": 180.0, "cap": 10 },
]


static func rarity_cap(rarity: int) -> int:
	return int(RARITY_GRADE_CAP.get(rarity, MAX_PSA))


static func mastery_cap(stability: float) -> int:
	var cap := MIN_PSA
	for band in MASTERY_BANDS:
		if stability >= float(band["min_stability"]):
			cap = int(band["cap"])
	return cap


## The top PSA this instance could reach = min(rarity ceiling, mastery reach).
static func ceiling(rarity: int, stability: float) -> int:
	return mini(rarity_cap(rarity), mastery_cap(stability))


static func is_raw(grade: int) -> bool:
	return grade <= RAW


static func grade_name(grade: int) -> String:
	if is_raw(grade):
		return "Raw"
	return "PSA %d" % grade
