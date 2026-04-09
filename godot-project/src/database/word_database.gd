## WordDatabase — Multi-character word data for future word fusion system.
## In Phase 1 this is a lightweight lookup; full fusion comes in Phase 3+.
class_name WordDatabase
extends RefCounted

var _words: Array[Dictionary] = []
var _by_characters: Dictionary = {}  # "电影" -> word dict
var _char_to_words: Dictionary = {}  # "电" -> Array[Dictionary] of words containing it
var _loaded: bool = false


func load_all() -> void:
	var raw: Variant = DataLoader.load_json(DataLoader.DATA_BASE_PATH + "words/words.json")
	if raw != null and raw is Array:
		_words = raw
	_build_indexes()
	_loaded = true


func load_from_array(words: Array[Dictionary]) -> void:
	_words = words
	_build_indexes()
	_loaded = true


func _build_indexes() -> void:
	_by_characters.clear()
	_char_to_words.clear()

	for w in _words:
		var word_str: String = w.get("word", "")
		if word_str == "":
			continue
		_by_characters[word_str] = w

		var chars: Array = w.get("characters", [])
		for ch in chars:
			var ch_str := str(ch)
			if ch_str not in _char_to_words:
				_char_to_words[ch_str] = []
			_char_to_words[ch_str].append(w)


func is_loaded() -> bool:
	return _loaded


func get_word(word_str: String) -> Dictionary:
	return _by_characters.get(word_str, {})


func has_word(word_str: String) -> bool:
	return word_str in _by_characters


## Get all words that contain a specific character.
func get_words_for_character(char_str: String) -> Array:
	return _char_to_words.get(char_str, [])


## Check if two characters can form a known word.
func can_fuse(char_a: String, char_b: String) -> bool:
	return has_word(char_a + char_b) or has_word(char_b + char_a)


## Get the word formed by two characters, if any.
func get_fusion_result(char_a: String, char_b: String) -> Dictionary:
	var forward := char_a + char_b
	if has_word(forward):
		return get_word(forward)
	var backward := char_b + char_a
	if has_word(backward):
		return get_word(backward)
	return {}


func get_count() -> int:
	return _words.size()
