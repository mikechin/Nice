## RadicalBonusCalculator — Computes passive character drops from owned radicals.
class_name RadicalBonusCalculator
extends RefCounted

var _radical_db: RadicalDatabase

const PASSIVE_DROP_CHANCE: float = 0.1
const TIER_MULTIPLIERS: Dictionary = {"common": 1.0, "rare": 1.5, "epic": 2.0}


func _init(radical_db: RadicalDatabase = null) -> void:
	_radical_db = radical_db


## Check for passive character drops from equipped radicals after answering a character.
func calculate_passive_drops(equipped_radicals: Array[String], answered_character: String) -> Array[String]:
	var drops: Array[String] = []
	if _radical_db == null:
		return drops

	for radical in equipped_radicals:
		var rd := _radical_db.get_radical(radical)
		if rd == null:
			continue

		# Check if answered character is in this radical's family
		if answered_character not in rd.characters:
			continue

		# Roll for passive drop
		var mult := get_bonus_multiplier(rd.rarity_tier)
		if randf() < PASSIVE_DROP_CHANCE * mult:
			var drop_char := _pick_random_family_member(rd, answered_character)
			if drop_char != "":
				drops.append(drop_char)

	return drops


func get_bonus_multiplier(radical_tier: String) -> float:
	return TIER_MULTIPLIERS.get(radical_tier, 1.0)


func _pick_random_family_member(radical_data: RadicalData, exclude: String) -> String:
	var candidates: Array[String] = []
	for ch in radical_data.characters:
		if ch != exclude:
			candidates.append(ch)
	if candidates.is_empty():
		return ""
	candidates.shuffle()
	return candidates[0]
