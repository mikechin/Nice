## RadicalData — Resource type for a single radical entry.
class_name RadicalData
extends Resource

@export var radical: String = ""
@export var meaning: String = ""
@export var characters: Array[String] = []
@export var display_name: String = ""

static func from_dict(data: Dictionary) -> RadicalData:
	var rd := RadicalData.new()
	rd.radical = data.get("radical", "")
	rd.meaning = data.get("meaning", "")
	rd.display_name = data.get("display_name", "")

	var raw_chars: Array = data.get("characters", [])
	for c in raw_chars:
		rd.characters.append(str(c))

	return rd

func to_dict() -> Dictionary:
	return {
		"radical": radical,
		"meaning": meaning,
		"characters": Array(characters),
		"display_name": display_name,
	}

func get_character_count() -> int:
	return characters.size()
