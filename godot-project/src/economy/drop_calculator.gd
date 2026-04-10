## DropCalculator — Determines what drops (coins, words, bonuses) from each correct answer.
class_name DropCalculator
extends RefCounted

var economy_scaler: EconomyScaler
var coin_manager: CoinManager
var _radical_db: RadicalDatabase


func _init(scaler: EconomyScaler = null, coins: CoinManager = null, rad_db: RadicalDatabase = null) -> void:
	economy_scaler = scaler if scaler else EconomyScaler.new()
	coin_manager = coins if coins else CoinManager.new()
	_radical_db = rad_db


func calculate_drops(
	card_data: CharacterData,
	loot_rarity: SrsEnums.LootRarity,
	hsk_level: int,
	equipped_radicals: Array[String]
) -> Dictionary:
	var result := {
		"coins": 0,
		"word_drop": {},
		"radical_bonus": {},
	}

	# Check radical bonus
	var has_radical_bonus := false
	if _radical_db:
		var char_radicals := _radical_db.get_radicals_for_character(card_data.character)
		for rad in char_radicals:
			if rad in equipped_radicals:
				has_radical_bonus = true
				var rad_data := _radical_db.get_radical(rad)
				result["radical_bonus"] = {
					"radical": rad,
					"bonus_coins": 5,
					"display_name": rad_data.display_name if rad_data else rad,
				}
				SignalBus.radical_activated.emit(rad, card_data.character, 5)
				break

	# Coin drops
	result["coins"] = coin_manager.calculate_coin_value(
		loot_rarity, hsk_level, has_radical_bonus
	)

	# Word drops (HSK 4+)
	if economy_scaler.should_drop_word(hsk_level, card_data):
		result["word_drop"] = economy_scaler.get_word_drop(card_data)
		if not result["word_drop"].is_empty():
			var word_chars: Array = result["word_drop"].get("characters", [])
			SignalBus.word_drop.emit(result["word_drop"].get("word", ""), word_chars)

	return result
