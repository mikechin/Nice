## SentenceDatabase — Loads and queries sentence templates for boss rounds and dailies.
class_name SentenceDatabase
extends RefCounted

var _sentences: Array[Dictionary] = []
var _by_id: Dictionary = {}            # sentence id -> Dictionary
var _by_level: Dictionary = {}         # hsk_level -> Array[Dictionary]
var _by_grammar: Dictionary = {}       # grammar_pattern -> Array[Dictionary]
var _weekly_trials: Array[Dictionary] = []
var _loaded: bool = false


func load_all(min_level: int = 2, max_level: int = 4) -> void:
	_sentences.clear()
	for level in range(min_level, max_level + 1):
		var level_sentences := DataLoader.load_sentences(level)
		_sentences.append_array(level_sentences)
	_weekly_trials = DataLoader.load_weekly_trials()
	_build_indexes()
	_loaded = true


func load_from_array(sentences: Array[Dictionary], trials: Array[Dictionary] = []) -> void:
	_sentences = sentences
	_weekly_trials = trials
	_build_indexes()
	_loaded = true


func _build_indexes() -> void:
	_by_id.clear()
	_by_level.clear()
	_by_grammar.clear()

	for s in _sentences:
		var sid: String = s.get("id", "")
		if sid != "":
			_by_id[sid] = s

		var level: int = s.get("hsk_level", 2)
		if level not in _by_level:
			_by_level[level] = []
		_by_level[level].append(s)

		var grammar: String = s.get("grammar_pattern", "")
		if grammar != "":
			if grammar not in _by_grammar:
				_by_grammar[grammar] = []
			_by_grammar[grammar].append(s)


func is_loaded() -> bool:
	return _loaded


func get_sentence(sentence_id: String) -> Dictionary:
	return _by_id.get(sentence_id, {})


func get_sentences_for_level(hsk_level: int) -> Array:
	return _by_level.get(hsk_level, [])


func get_sentences_for_grammar(pattern: String) -> Array:
	return _by_grammar.get(pattern, [])


## Get a deterministic daily sentence based on date string (e.g., "2026-04-09").
func get_daily_sentence(hsk_level: int, date: String) -> Dictionary:
	var pool: Array = get_sentences_for_level(hsk_level)
	if pool.is_empty():
		return {}
	# Deterministic selection based on date hash
	var hash_val := date.hash()
	var idx := absi(hash_val) % pool.size()
	return pool[idx]


## Get a deterministic weekly trial based on week string (e.g., "2026-W15").
func get_weekly_trial(hsk_level: int, week: String) -> Dictionary:
	if _weekly_trials.is_empty():
		return {}
	var hash_val := (week + str(hsk_level)).hash()
	var idx := absi(hash_val) % _weekly_trials.size()
	return _weekly_trials[idx]


## Find a sentence buildable from the player's available characters.
func get_boss_sentence(hsk_level: int, available_chars: Dictionary) -> Dictionary:
	var pool: Array = get_sentences_for_level(hsk_level)
	# Sort by character_count ascending (easier sentences first)
	pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("character_count", 99) < b.get("character_count", 99)
	)
	for s in pool:
		if _can_build(s, available_chars):
			return s
	return {}


## Check if a sentence can be built from available characters.
func _can_build(sentence: Dictionary, available_chars: Dictionary) -> bool:
	var needed: Dictionary = {}
	var chars: Array = sentence.get("characters", [])
	for ch in chars:
		var ch_str := str(ch)
		needed[ch_str] = needed.get(ch_str, 0) + 1

	for ch_str in needed:
		if available_chars.get(ch_str, 0) < needed[ch_str]:
			return false
	return true


func get_count() -> int:
	return _sentences.size()
