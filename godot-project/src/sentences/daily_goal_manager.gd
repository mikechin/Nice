## DailyGoalManager — Tracks daily sentence goals.
class_name DailyGoalManager
extends RefCounted

var today_sentence: Dictionary = {}
var is_completed: bool = false
var _sentence_db: SentenceDatabase

const DAILY_REWARD_COINS: int = 50
const DAILY_REWARD_BONUS_TILES: int = 3


func _init(sentence_db: SentenceDatabase = null) -> void:
	_sentence_db = sentence_db


func load_today(hsk_level: int) -> Dictionary:
	if _sentence_db == null:
		return {}
	var today := _get_today_string()
	today_sentence = _sentence_db.get_daily_sentence(hsk_level, today)
	is_completed = false
	return today_sentence


func check_completion(tile_inventory: Dictionary) -> bool:
	if today_sentence.is_empty():
		return false
	var chars: Array = today_sentence.get("characters", [])
	var needed: Dictionary = {}
	for ch in chars:
		var ch_str := str(ch)
		needed[ch_str] = needed.get(ch_str, 0) + 1
	for ch_str in needed:
		if tile_inventory.get(ch_str, 0) < needed[ch_str]:
			return false
	return true


func complete_daily(tiles_used: Array) -> Dictionary:
	if is_completed:
		return {}
	is_completed = true
	var score: int = today_sentence.get("tile_count", 0) * 15 + 50
	SignalBus.daily_sentence_completed.emit(
		today_sentence.get("id", ""),
		score
	)
	return {
		"score": score,
		"reward_coins": DAILY_REWARD_COINS,
		"reward_bonus_tiles": DAILY_REWARD_BONUS_TILES,
	}


func get_needed_tiles() -> Array[String]:
	var needed: Array[String] = []
	var chars: Array = today_sentence.get("characters", [])
	for ch in chars:
		needed.append(str(ch))
	return needed


func get_sentence_display() -> String:
	return today_sentence.get("sentence", "")


func get_sentence_meaning() -> String:
	return today_sentence.get("meaning", "")


func _get_today_string() -> String:
	var dt := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]
