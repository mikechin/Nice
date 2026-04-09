## DataLoader — Loads JSON data files from res://data/ at runtime.
class_name DataLoader
extends RefCounted

const DATA_BASE_PATH := "res://data/"


## Load and parse a JSON file, returning the parsed variant (Array or Dictionary).
## Returns null on failure.
static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("DataLoader: File not found: %s" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataLoader: Cannot open file: %s (error %d)" % [path, FileAccess.get_open_error()])
		return null

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		push_error("DataLoader: JSON parse error in %s at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null

	return json.data


## Save data as JSON to user:// path.
static func save_json(path: String, data: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("DataLoader: Cannot write to %s (error %d)" % [path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


## Load character data for a specific HSK level.
static func load_characters(hsk_level: int) -> Array[CharacterData]:
	var path := DATA_BASE_PATH + "hsk%d/characters.json" % hsk_level
	var raw: Variant = load_json(path)
	if raw == null or not raw is Array:
		return []

	var result: Array[CharacterData] = []
	for entry in raw:
		result.append(CharacterData.from_dict(entry))
	return result


## Load characters for multiple HSK levels.
static func load_characters_range(min_level: int, max_level: int) -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for level in range(min_level, max_level + 1):
		result.append_array(load_characters(level))
	return result


## Load radical data.
static func load_radicals() -> Array[RadicalData]:
	var path := DATA_BASE_PATH + "radicals/radicals.json"
	var raw: Variant = load_json(path)
	if raw == null or not raw is Array:
		return []

	var result: Array[RadicalData] = []
	for entry in raw:
		result.append(RadicalData.from_dict(entry))
	return result


## Load the radical-to-character mapping.
static func load_radical_character_map() -> Dictionary:
	var path := DATA_BASE_PATH + "radicals/radical_character_map.json"
	var raw: Variant = load_json(path)
	if raw == null or not raw is Dictionary:
		return {}
	return raw


## Load sentence data for a specific HSK level.
static func load_sentences(hsk_level: int) -> Array[Dictionary]:
	var path := DATA_BASE_PATH + "sentences/hsk%d_daily.json" % hsk_level
	var raw: Variant = load_json(path)
	if raw == null or not raw is Array:
		return []
	var result: Array[Dictionary] = []
	result.assign(raw)
	return result


## Load weekly trial data.
static func load_weekly_trials() -> Array[Dictionary]:
	var path := DATA_BASE_PATH + "sentences/weekly_trials.json"
	var raw: Variant = load_json(path)
	if raw == null or not raw is Array:
		return []
	var result: Array[Dictionary] = []
	result.assign(raw)
	return result


## Check if a data file exists.
static func file_exists(relative_path: String) -> bool:
	return FileAccess.file_exists(DATA_BASE_PATH + relative_path)
