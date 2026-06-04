## InstancePower — the flat-base power scalar for a card instance (Phase 3, M5).
##
## Replaces the OLD inverted model (barely-known = strongest — PowerEnums.BASE_POWER)
## with the design's overturned rule: power comes from what you EARNED, not from how
## poorly you know it. A card's combat magnitude scales with its print RARITY (luck
## at drop) and its PSA GRADE (mastery + craft) — exactly the two axes the economy
## already turns on. Knowledge (FSRS) fuels the FIGHT (it charges the ATB); it does
## NOT set card power. The scalar is what every effect's base magnitude is multiplied
## by (see CombatLoadout). Pure and testable; no SRS, no scene, no RNG.
##
## Floor is the common-raw card = 1.0 (×1 rarity, ×1 grade), so a fresh drop always
## carries its full base effect; rarity and grade only ever scale it UP.
class_name InstancePower
extends RefCounted

## Rolled print rarity → the base multiplier. Common is the 1.0 floor; epic (HSK-4
## stretch) triples. Mirrors the rarity ladder the economy already uses.
const RARITY_MULT := {
	EconomyEnums.Rarity.COMMON: 1.0,
	EconomyEnums.Rarity.UNCOMMON: 1.4,
	EconomyEnums.Rarity.RARE: 2.0,
	EconomyEnums.Rarity.EPIC: 3.0,
}

## Each PSA grade adds this much on top of raw. RAW (0) → ×1.0; PSA 10 → ×1.8.
const GRADE_STEP := 0.08


static func rarity_mult(rarity: int) -> float:
	return float(RARITY_MULT.get(rarity, 1.0))


## Grade multiplier: raw is the ×1.0 floor, every PSA grade adds GRADE_STEP.
static func grade_mult(grade: int) -> float:
	return 1.0 + maxi(0, grade) * GRADE_STEP


## The combined scalar (≥ 1.0) every effect base magnitude is multiplied by.
static func scalar(rarity: int, grade: int) -> float:
	return rarity_mult(rarity) * grade_mult(grade)
