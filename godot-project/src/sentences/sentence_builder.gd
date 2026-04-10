## SentenceBuilder — Core logic for the sentence building phase.
## Handles character placement, validation, and scoring.
class_name SentenceBuilder
extends RefCounted

var placed_chars: Array[String] = []
var available_chars: Dictionary = {}  # character -> count
var max_length: int = 10

const BASE_CHAR_SCORE: int = 10
const RARE_CHAR_BONUS: int = 25
const RADICAL_CHAR_BONUS: int = 15


func set_available_chars(chars: Dictionary) -> void:
	available_chars = chars.duplicate()


func place_char(character: String, position: int = -1) -> bool:
	if placed_chars.size() >= max_length:
		return false
	if available_chars.get(character, 0) <= 0:
		return false

	available_chars[character] -= 1
	if available_chars[character] <= 0:
		available_chars.erase(character)

	if position < 0 or position >= placed_chars.size():
		placed_chars.append(character)
	else:
		placed_chars.insert(position, character)
	return true


func remove_char(position: int) -> String:
	if position < 0 or position >= placed_chars.size():
		return ""
	var character := placed_chars[position]
	placed_chars.remove_at(position)
	available_chars[character] = available_chars.get(character, 0) + 1
	return character


func clear_sentence() -> void:
	for ch in placed_chars:
		available_chars[ch] = available_chars.get(ch, 0) + 1
	placed_chars.clear()


func get_current_sentence() -> String:
	return "".join(placed_chars)


func get_placed_count() -> int:
	return placed_chars.size()


func calculate_score(sentence: String, srs_rare_chars: Array, radical_chars: Array) -> int:
	var score := 0
	for ch in sentence:
		var ch_str := String.chr(ch.unicode_at(0)) if ch is String else str(ch)
		score += BASE_CHAR_SCORE
		if ch_str in srs_rare_chars:
			score += RARE_CHAR_BONUS
		if ch_str in radical_chars:
			score += RADICAL_CHAR_BONUS
	# Length bonus
	score += placed_chars.size() * 5
	return score
