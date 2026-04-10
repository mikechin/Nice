## BossRoundManager — Controls boss round sentence challenges at end of run.
## Randomly selects challenge type and generates appropriate content.
class_name BossRoundManager
extends RefCounted

enum BossType { FILL_BLANK, SCRAMBLE, FREE_BUILD }

var current_boss_type: BossType
var current_challenge: Dictionary = {}

var _sentence_db: SentenceDatabase
var _validator: SentenceValidator


func _init(sentence_db: SentenceDatabase = null) -> void:
	_sentence_db = sentence_db
	_validator = SentenceValidator.new(sentence_db)


func generate_boss_round(hsk_level: int, available_chars: Dictionary) -> Dictionary:
	if _sentence_db == null:
		return {}

	# Find a sentence buildable from available characters
	var sentence := _sentence_db.get_boss_sentence(hsk_level, available_chars)
	if sentence.is_empty():
		return {}

	# Randomly pick challenge type
	var types := [BossType.FILL_BLANK, BossType.SCRAMBLE, BossType.FREE_BUILD]
	types.shuffle()
	current_boss_type = types[0]

	match current_boss_type:
		BossType.FILL_BLANK:
			current_challenge = _generate_fill_blank(sentence)
		BossType.SCRAMBLE:
			current_challenge = _generate_scramble(sentence)
		BossType.FREE_BUILD:
			current_challenge = _generate_free_build(sentence)

	current_challenge["boss_type"] = current_boss_type
	current_challenge["sentence_data"] = sentence

	SignalBus.boss_round_started.emit(get_boss_type_name())
	return current_challenge


func submit_answer(answer: Variant) -> Dictionary:
	var correct := false
	var score := 0

	match current_boss_type:
		BossType.FILL_BLANK:
			correct = _validator.validate_fill_blank(
				current_challenge.get("sentence_with_blank", ""),
				current_challenge.get("blank_position", -1),
				str(answer)
			)
		BossType.SCRAMBLE:
			correct = _validator.validate_scramble(
				current_challenge.get("original", ""),
				str(answer)
			)
		BossType.FREE_BUILD:
			correct = _validator.validate_free_build(
				current_challenge.get("meaning", ""),
				str(answer)
			)

	if correct:
		score = _calculate_score()
		SignalBus.boss_round_completed.emit(score)
	else:
		SignalBus.boss_round_failed.emit()

	return {"correct": correct, "score": score}


func get_boss_type_name() -> String:
	match current_boss_type:
		BossType.FILL_BLANK: return "Fill in the Blank"
		BossType.SCRAMBLE: return "Unscramble"
		BossType.FREE_BUILD: return "Free Build"
	return ""


func _generate_fill_blank(sentence: Dictionary) -> Dictionary:
	var chars: Array = sentence.get("characters", [])
	if chars.is_empty():
		return {}
	var blank_idx := randi() % chars.size()
	var answer: String = chars[blank_idx]
	var display_chars := chars.duplicate()
	display_chars[blank_idx] = "___"
	return {
		"type": "fill_blank",
		"display": "".join(display_chars),
		"sentence_with_blank": sentence.get("sentence", ""),
		"blank_position": blank_idx,
		"answer": answer,
		"meaning": sentence.get("meaning", ""),
	}


func _generate_scramble(sentence: Dictionary) -> Dictionary:
	var chars: Array = sentence.get("characters", []).duplicate()
	var original: String = sentence.get("sentence", "")
	chars.shuffle()
	return {
		"type": "scramble",
		"scrambled_characters": chars,
		"original": original,
		"meaning": sentence.get("meaning", ""),
	}


func _generate_free_build(sentence: Dictionary) -> Dictionary:
	return {
		"type": "free_build",
		"meaning": sentence.get("meaning", ""),
		"expected_sentence": sentence.get("sentence", ""),
		"hint_character_count": sentence.get("character_count", 0),
	}


func _calculate_score() -> int:
	var sentence_data: Dictionary = current_challenge.get("sentence_data", {})
	var character_count: int = sentence_data.get("character_count", 0)
	return character_count * 20 + 100
