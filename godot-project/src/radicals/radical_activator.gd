## RadicalActivator — Detects and triggers radical bonuses during gameplay.
## Mode 1: Recognition (radical highlights in presented character)
## Mode 2: Attach (special event — add radical to base character)
class_name RadicalActivator
extends RefCounted

var _radical_db: RadicalDatabase
var _radical_manager: RadicalManager

const BASE_RADICAL_BONUS: int = 5
const RARE_RADICAL_MULT: float = 1.5
const EPIC_RADICAL_MULT: float = 2.0


func _init(radical_db: RadicalDatabase = null, radical_manager: RadicalManager = null) -> void:
	_radical_db = radical_db
	_radical_manager = radical_manager


func check_activation(card_data: CharacterData) -> Dictionary:
	if _radical_db == null or _radical_manager == null:
		return {"activated": false}

	var matching := get_matching_radicals(card_data.character)
	if matching.is_empty():
		return {"activated": false}

	# Use the first matching equipped radical
	var radical: String = matching[0]
	var bonus := calculate_radical_bonus(radical, card_data, 0)

	SignalBus.radical_activated.emit(radical, card_data.character, bonus)

	return {
		"activated": true,
		"radical": radical,
		"bonus_coins": bonus,
		"mode": "recognition",
		"all_matching": matching,
	}


## Which equipped radicals appear in this character?
func get_matching_radicals(character: String) -> Array[String]:
	if _radical_db == null or _radical_manager == null:
		return []
	var char_radicals := _radical_db.get_radicals_for_character(character)
	var equipped := _radical_manager.get_equipped()
	var matching: Array[String] = []
	for rad in char_radicals:
		if rad in equipped:
			matching.append(rad)
	return matching


func can_trigger_attach(card_data: CharacterData) -> bool:
	# Attach mode: character is a standalone base that can have a radical added
	return card_data.is_radical and _radical_manager != null and not _radical_manager.get_equipped().is_empty()


func calculate_radical_bonus(radical: String, card_data: CharacterData, combo: int) -> int:
	var base := BASE_RADICAL_BONUS
	# Rarity multiplier
	if _radical_db:
		var rd := _radical_db.get_radical(radical)
		if rd:
			if rd.is_epic():
				base = roundi(float(base) * EPIC_RADICAL_MULT)
			elif rd.is_rare():
				base = roundi(float(base) * RARE_RADICAL_MULT)
	return base


func get_passive_tile_drop(radical: String) -> String:
	if _radical_db == null:
		return ""
	var chars := _radical_db.get_characters_for_radical(radical)
	if chars.is_empty():
		return ""
	chars.shuffle()
	return chars[0]
