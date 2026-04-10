## RadicalDatabase — In-memory database of all radicals.
class_name RadicalDatabase
extends RefCounted

var _radicals: Array[RadicalData] = []
var _by_radical: Dictionary = {}       # radical string -> RadicalData
var _char_to_radicals: Dictionary = {} # character string -> Array[String] (radical strings)
var _loaded: bool = false


func load_all() -> void:
	_radicals = DataLoader.load_radicals()
	_build_indexes()
	_loaded = true


func load_from_array(radicals: Array[RadicalData]) -> void:
	_radicals = radicals
	_build_indexes()
	_loaded = true


func _build_indexes() -> void:
	_by_radical.clear()
	_char_to_radicals.clear()

	for rd in _radicals:
		_by_radical[rd.radical] = rd

		for ch in rd.characters:
			if ch not in _char_to_radicals:
				_char_to_radicals[ch] = []
			_char_to_radicals[ch].append(rd.radical)


func is_loaded() -> bool:
	return _loaded


func get_all() -> Array[RadicalData]:
	return _radicals


func get_count() -> int:
	return _radicals.size()


func get_radical(radical_str: String) -> RadicalData:
	return _by_radical.get(radical_str)


func has_radical(radical_str: String) -> bool:
	return radical_str in _by_radical


## Get all radicals that a character contains.
func get_radicals_for_character(char_str: String) -> Array[String]:
	var result: Array[String] = []
	var raw: Array = _char_to_radicals.get(char_str, [])
	for r in raw:
		result.append(str(r))
	return result


## Get all characters that contain a specific radical.
func get_characters_for_radical(radical_str: String) -> Array[String]:
	var rd := get_radical(radical_str)
	if rd == null:
		return []
	return rd.characters


## Check if a character has a specific radical.
func character_has_radical(char_str: String, radical_str: String) -> bool:
	var radicals := get_radicals_for_character(char_str)
	return radical_str in radicals
