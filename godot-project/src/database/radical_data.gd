## RadicalData — Resource type for a single radical entry.
class_name RadicalData
extends Resource

@export var radical: String = ""
@export var meaning: String = ""
@export var rarity_tier: String = "common"
@export var shop_cost: int = 50
@export var characters: Array[String] = []
@export var display_name: String = ""

static func from_dict(data: Dictionary) -> RadicalData:
	var rd := RadicalData.new()
	rd.radical = data.get("radical", "")
	rd.meaning = data.get("meaning", "")
	rd.rarity_tier = data.get("rarity_tier", "common")
	rd.shop_cost = data.get("shop_cost", 50)
	rd.display_name = data.get("display_name", "")

	var raw_chars: Array = data.get("characters", [])
	for c in raw_chars:
		rd.characters.append(str(c))

	return rd

func to_dict() -> Dictionary:
	return {
		"radical": radical,
		"meaning": meaning,
		"rarity_tier": rarity_tier,
		"shop_cost": shop_cost,
		"characters": Array(characters),
		"display_name": display_name,
	}

func get_character_count() -> int:
	return characters.size()

func is_epic() -> bool:
	return rarity_tier == "epic"

func is_rare() -> bool:
	return rarity_tier == "rare"
