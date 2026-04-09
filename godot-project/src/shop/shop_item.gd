## ShopItem — Data model for an item in the shop.
class_name ShopItem
extends RefCounted

enum ItemType { RADICAL, UTILITY_TILE, EXTRA_HEART, PACK_REFRESH }

var item_type: ItemType
var item_id: String = ""
var display_name: String = ""
var description: String = ""
var cost: int = 0
var data: Dictionary = {}  # Type-specific data
var is_sold: bool = false


static func create_radical(radical_data: RadicalData) -> ShopItem:
	var item := ShopItem.new()
	item.item_type = ItemType.RADICAL
	item.item_id = "radical_" + radical_data.radical
	item.display_name = radical_data.display_name
	item.description = "Radical: %s (%s)" % [radical_data.radical, radical_data.meaning]
	item.cost = radical_data.shop_cost
	item.data = {"radical": radical_data.radical, "rarity_tier": radical_data.rarity_tier}
	return item


static func create_utility_tile(character: String, cost_val: int) -> ShopItem:
	var item := ShopItem.new()
	item.item_type = ItemType.UTILITY_TILE
	item.item_id = "tile_" + character
	item.display_name = character
	item.description = "Character tile"
	item.cost = cost_val
	item.data = {"character": character}
	return item


static func create_extra_heart(cost_val: int = 50) -> ShopItem:
	var item := ShopItem.new()
	item.item_type = ItemType.EXTRA_HEART
	item.item_id = "extra_heart"
	item.display_name = "Extra Heart"
	item.description = "+1 heart for your next run"
	item.cost = cost_val
	return item


static func create_pack_refresh(cost_val: int = 30) -> ShopItem:
	var item := ShopItem.new()
	item.item_type = ItemType.PACK_REFRESH
	item.item_id = "pack_refresh"
	item.display_name = "Pack Refresh"
	item.description = "Re-roll your next pack"
	item.cost = cost_val
	return item


func to_dict() -> Dictionary:
	return {
		"item_type": item_type,
		"item_id": item_id,
		"display_name": display_name,
		"description": description,
		"cost": cost,
		"data": data,
		"is_sold": is_sold,
	}
