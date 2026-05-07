## BonusTrigger — Decides whether a card kicks off a bonus round.
##
## Spec: rare/epic-tier cards have a 20% chance to trigger a bonus round on
## a correct primary-challenge answer. Commons (mastered routine reviews)
## never trigger — that would slow down the rhythmic flow that makes
## opening a pack feel good.
##
## RNG is injectable so tests can seed deterministically.
class_name BonusTrigger
extends RefCounted


## Loot rarities that are eligible to fire a bonus round. COMMON is excluded
## by design — the bonus round is the dopamine spike for non-routine cards.
const ELIGIBLE_RARITIES: Array = [
	SrsEnums.LootRarity.LEARNING,
	SrsEnums.LootRarity.ABOUT_TO_FORGET,
	SrsEnums.LootRarity.NEW_CARD,
]


static func is_eligible(rarity: SrsEnums.LootRarity) -> bool:
	return rarity in ELIGIBLE_RARITIES


## Roll the trigger. If `rng` is null, a fresh randomized RNG is created.
## Returns NOT_TRIGGERED for ineligible rarities without rolling so callers
## can see "didn't fire" without consuming randomness.
static func roll(rarity: SrsEnums.LootRarity, rng: RandomNumberGenerator = null) -> BonusEnums.BonusOutcome:
	if not is_eligible(rarity):
		return BonusEnums.BonusOutcome.NOT_TRIGGERED

	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()

	if generator.randf() < BonusEnums.BONUS_TRIGGER_CHANCE:
		return BonusEnums.BonusOutcome.TRIGGERED
	return BonusEnums.BonusOutcome.NOT_TRIGGERED
