## RarityRoll — the weighted drop-time rarity roll (Phase 3, M3, decision D7).
##
## Rarity is ROLLED when an instance drops, NOT read from HSK level or SRS
## stability. The roll favors common heavily but gives every launch-active tier
## a nonzero floor from the very first drop, then shifts probability mass upward
## with:
##   - depth   — deeper rooms drop better (the push-your-luck payoff)
##   - streak  — consecutive correct answers in the room
##   - clutch  — an ABOUT_TO_FORGET card recalled correctly (the rare clutch win)
##
## COMMON's weight is held flat while the upper tiers grow, so the *share* of
## commons falls as you earn the modifiers — that's the "weighted up" the design
## calls for. EPIC stays at zero weight until the HSK-4 stretch (see
## EconomyEnums.LAUNCH_MAX_RARITY).
##
## Pure + deterministic: `weights`/`probabilities` are side-effect-free and
## `roll` takes an injectable RNG, so the curve is unit-testable without
## statistical flakiness.
class_name RarityRoll
extends RefCounted

# Base weights at depth 0, no streak, no clutch. Common dominates; uncommon and
# rare keep a nonzero floor (rare can roll from drop #1 — ~4%).
const BASE := {
	EconomyEnums.Rarity.COMMON: 80.0,
	EconomyEnums.Rarity.UNCOMMON: 16.0,
	EconomyEnums.Rarity.RARE: 4.0,
	EconomyEnums.Rarity.EPIC: 0.0,      # gated until LAUNCH_MAX_RARITY lifts
}
# Additive weight per unit of each modifier — only the upper tiers grow.
const DEPTH_BONUS := { EconomyEnums.Rarity.UNCOMMON: 3.0, EconomyEnums.Rarity.RARE: 1.6 }
const STREAK_BONUS := { EconomyEnums.Rarity.UNCOMMON: 1.1, EconomyEnums.Rarity.RARE: 0.7 }
const CLUTCH_BONUS := { EconomyEnums.Rarity.UNCOMMON: 6.0, EconomyEnums.Rarity.RARE: 4.0 }

const MAX_DEPTH := 10
const MAX_STREAK := 20


## The full weight table for a drop context. Tiers above the launch ceiling are
## forced to zero. Pure — `roll` and `probabilities` both build on this.
static func weights(depth: int, streak: int, clutch: bool) -> Dictionary:
	var d := float(clampi(depth, 0, MAX_DEPTH))
	var s := float(clampi(streak, 0, MAX_STREAK))
	var out := {}
	for r in EconomyEnums.all_rarities():
		var w: float = BASE.get(r, 0.0)
		w += d * float(DEPTH_BONUS.get(r, 0.0))
		w += s * float(STREAK_BONUS.get(r, 0.0))
		if clutch:
			w += float(CLUTCH_BONUS.get(r, 0.0))
		if int(r) > int(EconomyEnums.LAUNCH_MAX_RARITY):
			w = 0.0
		out[r] = w
	return out


## Normalized probabilities — handy for the "show the odds" teaching hook and
## for asserting the curve in tests.
static func probabilities(depth: int, streak: int, clutch: bool) -> Dictionary:
	var w := weights(depth, streak, clutch)
	var total := 0.0
	for r in w:
		total += w[r]
	var out := {}
	for r in w:
		out[r] = (w[r] / total) if total > 0.0 else 0.0
	return out


## Roll one rarity for a drop. `rng` is injectable for deterministic tests;
## omit it for a freshly randomized generator.
static func roll(depth: int, streak: int, clutch: bool, rng: RandomNumberGenerator = null) -> int:
	var gen := rng
	if gen == null:
		gen = RandomNumberGenerator.new()
		gen.randomize()
	var w := weights(depth, streak, clutch)
	var total := 0.0
	for r in w:
		total += w[r]
	if total <= 0.0:
		return EconomyEnums.Rarity.COMMON
	var pick := gen.randf() * total
	var acc := 0.0
	for r in EconomyEnums.all_rarities():
		acc += float(w.get(r, 0.0))
		if pick < acc:
			return r
	return EconomyEnums.Rarity.COMMON
