## SentenceBuilder — Core logic for the sentence building phase.
## Handles tile placement, validation, and scoring.
class_name SentenceBuilder
extends RefCounted

var placed_tiles: Array[String] = []
var available_tiles: Dictionary = {}  # character -> count
var max_length: int = 10

const BASE_TILE_SCORE: int = 10
const RARE_TILE_BONUS: int = 25
const RADICAL_TILE_BONUS: int = 15


func set_available_tiles(tiles: Dictionary) -> void:
	available_tiles = tiles.duplicate()


func place_tile(character: String, position: int = -1) -> bool:
	if placed_tiles.size() >= max_length:
		return false
	if available_tiles.get(character, 0) <= 0:
		return false

	available_tiles[character] -= 1
	if available_tiles[character] <= 0:
		available_tiles.erase(character)

	if position < 0 or position >= placed_tiles.size():
		placed_tiles.append(character)
	else:
		placed_tiles.insert(position, character)
	return true


func remove_tile(position: int) -> String:
	if position < 0 or position >= placed_tiles.size():
		return ""
	var character := placed_tiles[position]
	placed_tiles.remove_at(position)
	available_tiles[character] = available_tiles.get(character, 0) + 1
	return character


func clear_sentence() -> void:
	for ch in placed_tiles:
		available_tiles[ch] = available_tiles.get(ch, 0) + 1
	placed_tiles.clear()


func get_current_sentence() -> String:
	return "".join(placed_tiles)


func get_placed_count() -> int:
	return placed_tiles.size()


func calculate_score(sentence: String, srs_rare_tiles: Array, radical_tiles: Array) -> int:
	var score := 0
	for ch in sentence:
		var ch_str := String.chr(ch.unicode_at(0)) if ch is String else str(ch)
		score += BASE_TILE_SCORE
		if ch_str in srs_rare_tiles:
			score += RARE_TILE_BONUS
		if ch_str in radical_tiles:
			score += RADICAL_TILE_BONUS
	# Length bonus
	score += placed_tiles.size() * 5
	return score
