## PowerCalculator — Static helpers for board-game power.
## Power has one pure-data input (LootRarity → base) and a list of additive
## boosts (PowerBoost). Phase 2 only emits BONUS_STAGE boosts; Phase 3 will
## add radical/rime boosts through the same path.
class_name PowerCalculator
extends RefCounted


## Look up base power for a loot rarity. Unknown rarities fall back to 1
## (treated as the weakest, mastered case).
static func base_power(rarity: SrsEnums.LootRarity) -> int:
	return PowerEnums.BASE_POWER.get(rarity, 1)


## Sum the amount of every PowerBoost in the list.
static func total_boost(boosts: Array[PowerBoost]) -> int:
	var sum := 0
	for b in boosts:
		if b != null:
			sum += b.amount
	return sum


## Final power = base + sum(boosts). Never returns less than 0.
static func total_power(rarity: SrsEnums.LootRarity, boosts: Array[PowerBoost]) -> int:
	return maxi(0, base_power(rarity) + total_boost(boosts))
