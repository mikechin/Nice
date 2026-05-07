## HandCard — Resource describing one card carried out of a draft into the
## board-game phase. Records the card's identity, its base power at draft
## time, and the PowerBoosts earned during any bonus round.
##
## The board game (Phase 3) will read total_power off these to decide
## adjacency outcomes. Phase 2 just builds the data; nothing consumes it
## yet beyond the run summary.
class_name HandCard
extends Resource

@export var card_id: String = ""
## Base power frozen at draft time. Stored explicitly so a later change to
## the LootRarity → power table doesn't retroactively rewrite a run that
## already shipped to a save file.
@export var base_power: int = 0
@export var boosts: Array[PowerBoost] = []


static func create(card_id_: String, base_power_: int, boosts_: Array) -> HandCard:
	var hc := HandCard.new()
	hc.card_id = card_id_
	hc.base_power = base_power_
	var typed: Array[PowerBoost] = []
	for b in boosts_:
		if b is PowerBoost:
			typed.append(b)
	hc.boosts = typed
	return hc


func get_total_power() -> int:
	return maxi(0, base_power + PowerCalculator.total_boost(boosts))


func to_dict() -> Dictionary:
	var boost_dicts: Array = []
	for b in boosts:
		boost_dicts.append(b.to_dict())
	return {
		"card_id": card_id,
		"base_power": base_power,
		"boosts": boost_dicts,
	}


static func from_dict(data: Dictionary) -> HandCard:
	var hc := HandCard.new()
	hc.card_id = data.get("card_id", "")
	hc.base_power = data.get("base_power", 0)
	var raw_boosts: Array = data.get("boosts", [])
	var typed: Array[PowerBoost] = []
	for bd in raw_boosts:
		if bd is Dictionary:
			typed.append(PowerBoost.from_dict(bd))
	hc.boosts = typed
	return hc
