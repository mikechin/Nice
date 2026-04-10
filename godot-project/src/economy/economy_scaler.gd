## EconomyScaler — Scales rewards based on HSK level to prevent grinding.
## Higher levels earn more coins per answer, get word drops, etc.
class_name EconomyScaler
extends RefCounted

const WORD_DROP_MIN_LEVEL: int = 4
const WORD_DROP_CHANCE: float = 0.15
const BOSS_REWARD_MULTIPLIERS: Dictionary = {2: 1.0, 3: 1.5, 4: 2.0, 5: 3.0}

var _word_db: WordDatabase


func _init(word_db: WordDatabase = null) -> void:
	_word_db = word_db


func should_drop_word(hsk_level: int, card_data: CharacterData) -> bool:
	if hsk_level < WORD_DROP_MIN_LEVEL:
		return false
	if _word_db == null:
		return false
	# Check if this character participates in any known words
	var words := _word_db.get_words_for_character(card_data.character)
	if words.is_empty():
		return false
	return randf() < WORD_DROP_CHANCE


func get_word_drop(card_data: CharacterData) -> Dictionary:
	if _word_db == null:
		return {}
	var words := _word_db.get_words_for_character(card_data.character)
	if words.is_empty():
		return {}
	words.shuffle()
	return words[0]


func get_boss_reward_multiplier(hsk_level: int) -> float:
	return BOSS_REWARD_MULTIPLIERS.get(hsk_level, 1.0)
