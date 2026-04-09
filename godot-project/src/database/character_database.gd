## CharacterDatabase — In-memory database of all HSK characters.
## Provides fast lookup by character, pinyin, radical, HSK level, etc.
class_name CharacterDatabase
extends RefCounted

var _characters: Array[CharacterData] = []
var _by_char: Dictionary = {}         # character string -> CharacterData
var _by_hsk: Dictionary = {}          # hsk_level -> Array[CharacterData]
var _by_radical: Dictionary = {}      # radical string -> Array[CharacterData]
var _by_tone: Dictionary = {}         # tone int -> Array[CharacterData]
var _by_pinyin: Dictionary = {}       # base pinyin -> Array[CharacterData]
var _loaded: bool = false


func load_all(min_level: int = 2, max_level: int = 5) -> void:
	_characters = DataLoader.load_characters_range(min_level, max_level)
	_build_indexes()
	_loaded = true


func load_from_array(characters: Array[CharacterData]) -> void:
	_characters = characters
	_build_indexes()
	_loaded = true


func _build_indexes() -> void:
	_by_char.clear()
	_by_hsk.clear()
	_by_radical.clear()
	_by_tone.clear()
	_by_pinyin.clear()

	for cd in _characters:
		_by_char[cd.character] = cd

		if cd.hsk_level not in _by_hsk:
			_by_hsk[cd.hsk_level] = []
		_by_hsk[cd.hsk_level].append(cd)

		if cd.tone not in _by_tone:
			_by_tone[cd.tone] = []
		_by_tone[cd.tone].append(cd)

		var base_py := cd.get_base_pinyin()
		if base_py not in _by_pinyin:
			_by_pinyin[base_py] = []
		_by_pinyin[base_py].append(cd)

		for radical in cd.radicals:
			if radical not in _by_radical:
				_by_radical[radical] = []
			_by_radical[radical].append(cd)


func is_loaded() -> bool:
	return _loaded


func get_all() -> Array[CharacterData]:
	return _characters


func get_count() -> int:
	return _characters.size()


func get_character(char_str: String) -> CharacterData:
	return _by_char.get(char_str)


func has_character(char_str: String) -> bool:
	return char_str in _by_char


func get_by_hsk_level(level: int) -> Array:
	return _by_hsk.get(level, [])


func get_by_radical(radical: String) -> Array:
	return _by_radical.get(radical, [])


func get_by_tone(tone: int) -> Array:
	return _by_tone.get(tone, [])


func get_by_pinyin(base_pinyin: String) -> Array:
	return _by_pinyin.get(base_pinyin, [])


func get_character_count_for_level(hsk_level: int) -> int:
	return get_by_hsk_level(hsk_level).size()


## Get characters sharing a radical with the given character (for distractors).
func get_same_radical_characters(char_str: String) -> Array[CharacterData]:
	var cd := get_character(char_str)
	if cd == null:
		return []
	var result: Array[CharacterData] = []
	var seen := {char_str: true}
	for radical in cd.radicals:
		for other in get_by_radical(radical):
			if other.character not in seen:
				result.append(other)
				seen[other.character] = true
	return result


## Get characters with similar pinyin (for distractors).
func get_similar_pinyin_characters(char_str: String) -> Array[CharacterData]:
	var cd := get_character(char_str)
	if cd == null:
		return []
	var base := cd.get_base_pinyin()
	var result: Array[CharacterData] = []
	for other in get_by_pinyin(base):
		if other.character != char_str:
			result.append(other)
	return result


## Get characters with the same tone (for distractors).
func get_same_tone_characters(char_str: String) -> Array[CharacterData]:
	var cd := get_character(char_str)
	if cd == null:
		return []
	var result: Array[CharacterData] = []
	for other in get_by_tone(cd.tone):
		if other.character != char_str:
			result.append(other)
	return result


## Get random characters from the same HSK level (fallback distractors).
func get_random_same_level(char_str: String, count: int) -> Array[CharacterData]:
	var cd := get_character(char_str)
	if cd == null:
		return []
	var pool: Array = get_by_hsk_level(cd.hsk_level).duplicate()
	pool.shuffle()
	var result: Array[CharacterData] = []
	for other in pool:
		if result.size() >= count:
			break
		if other.character != char_str:
			result.append(other)
	return result


## Get all unique radicals referenced by loaded characters.
func get_all_radicals() -> Array[String]:
	var radicals: Array[String] = []
	for r in _by_radical:
		radicals.append(r)
	return radicals


## Get all unique HSK levels in the database.
func get_hsk_levels() -> Array[int]:
	var levels: Array[int] = []
	for l in _by_hsk:
		levels.append(l)
	levels.sort()
	return levels
