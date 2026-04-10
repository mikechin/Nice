## ShopManager — Controls shop inventory, rotation, and purchases.
class_name ShopManager
extends RefCounted

var current_inventory: Array[ShopItem] = []
var refresh_count: int = 0

var _rotation: ShopRotation
var _coin_manager: CoinManager
var _radical_manager: RadicalManager

const REFRESH_COST_BASE: int = 20
const REFRESH_COST_INCREASE: int = 10


func _init(
	rotation: ShopRotation = null,
	coins: CoinManager = null,
	radicals: RadicalManager = null
) -> void:
	_rotation = rotation if rotation else ShopRotation.new()
	_coin_manager = coins if coins else CoinManager.new()
	_radical_manager = radicals if radicals else RadicalManager.new()


func generate_inventory(player_level: int, owned_radicals: Array[String]) -> Array[ShopItem]:
	current_inventory = _rotation.generate_rotation(player_level, owned_radicals)
	refresh_count = 0
	SignalBus.shop_refreshed.emit(_inventory_to_array())
	return current_inventory


func purchase_item(item: ShopItem) -> bool:
	if item.is_sold:
		return false
	if not _coin_manager.spend_coins(item.cost):
		return false

	item.is_sold = true

	match item.item_type:
		ShopItem.ItemType.RADICAL:
			_radical_manager.purchase_radical(item.data.get("radical", ""))
		ShopItem.ItemType.PACK_REFRESH:
			pass  # Handled by pack curator

	SignalBus.item_purchased.emit(item.to_dict())
	return true


func refresh_shop(player_level: int, owned_radicals: Array[String]) -> bool:
	var cost := get_refresh_cost()
	if not _coin_manager.spend_coins(cost):
		return false
	refresh_count += 1
	generate_inventory(player_level, owned_radicals)
	return true


func get_refresh_cost() -> int:
	return REFRESH_COST_BASE + REFRESH_COST_INCREASE * refresh_count


func get_current_inventory() -> Array[ShopItem]:
	return current_inventory


func _inventory_to_array() -> Array:
	var result: Array = []
	for item in current_inventory:
		result.append(item.to_dict())
	return result
