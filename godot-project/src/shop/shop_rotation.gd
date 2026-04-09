## ShopRotation — Determines what appears in the shop each session.
## Not all items are available every time — creates urgency.
class_name ShopRotation
extends RefCounted

var _radical_db: RadicalDatabase

const RADICAL_SLOTS: int = 3
const TILE_SLOTS: int = 2
const UTILITY_SLOTS: int = 1
const TILE_BASE_COST: int = 15


func _init(radical_db: RadicalDatabase = null) -> void:
	_radical_db = radical_db


func generate_rotation(player_level: int, owned_radicals: Array[String]) -> Array[ShopItem]:
	var items: Array[ShopItem] = []

	# Radical slots
	var available_radicals := get_available_radicals(player_level, owned_radicals, RADICAL_SLOTS)
	items.append_array(available_radicals)

	# Utility tile slots
	var tiles := get_utility_tiles(player_level, TILE_SLOTS)
	items.append_array(tiles)

	# Always-available utility items
	items.append(ShopItem.create_extra_heart())
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


func get_utility_tiles(player_level: int, count: int) -> Array[ShopItem]:
	# Offer common character tiles below player level
	var result: Array[ShopItem] = []
	var common_chars: Array[String] = ["的", "了", "是", "我", "不", "人", "他", "们", "有", "这"]
	common_chars.shuffle()
	for i in mini(count, common_chars.size()):
		result.append(ShopItem.create_utility_tile(common_chars[i], TILE_BASE_COST))
	return result
