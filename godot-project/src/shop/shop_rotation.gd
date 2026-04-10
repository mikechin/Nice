## ShopRotation — Determines what appears in the shop each session.
## Not all items are available every time — creates urgency.
class_name ShopRotation
extends RefCounted

var _radical_db: RadicalDatabase

const RADICAL_SLOTS: int = 3
const UTILITY_SLOTS: int = 1


func _init(radical_db: RadicalDatabase = null) -> void:
	_radical_db = radical_db


func generate_rotation(player_level: int, owned_radicals: Array[String]) -> Array[ShopItem]:
	var items: Array[ShopItem] = []

	# Radical slots
	var available_radicals := get_available_radicals(player_level, owned_radicals, RADICAL_SLOTS)
	items.append_array(available_radicals)

	# Always-available utility items
	items.append(ShopItem.create_pack_refresh())

	return items


func get_available_radicals(player_level: int, owned: Array, count: int) -> Array[ShopItem]:
	if _radical_db == null:
		return []
	var result: Array[ShopItem] = []
	var all_radicals := _radical_db.get_all()
	all_radicals.shuffle()

	for rd in all_radicals:
		if result.size() >= count:
			break
		if rd.radical in owned:
			continue
		# Only show radicals appropriate for player level
		if rd.is_epic() and player_level < 4:
			continue
		if rd.is_rare() and player_level < 3:
			continue
		result.append(ShopItem.create_radical(rd))

	return result


