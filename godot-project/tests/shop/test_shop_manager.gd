## Tests for ShopManager — inventory generation, purchases, and refresh.
extends GdUnitTestSuite

var _shop: ShopManager
var _coins: CoinManager
var _radicals: RadicalManager
var _tiles: TileInventory
var _radical_db: RadicalDatabase
var _rotation: ShopRotation


func before_test() -> void:
	# Build a small radical database for the shop rotation
	_radical_db = RadicalDatabase.new()
	var rad_list: Array[RadicalData] = []
	for i in 5:
		var rd := RadicalData.from_dict({
			"radical": "rad_%d" % i,
			"meaning": "radical %d" % i,
			"rarity_tier": "common",
			"shop_cost": 50 + i * 10,
			"display_name": "Radical %d" % i,
			"characters": ["char_%d" % i],
		})
		rad_list.append(rd)
	_radical_db.load_from_array(rad_list)

	_coins = CoinManager.new()
	_radicals = RadicalManager.new()
	_tiles = TileInventory.new()
	_rotation = ShopRotation.new(_radical_db)
	_shop = ShopManager.new(_rotation, _coins, _radicals, _tiles)


# -- generate_inventory --

func test_generate_inventory_produces_items() -> void:
	var items := _shop.generate_inventory(2, [])
	assert_bool(items.size() > 0).is_true()


func test_generate_inventory_includes_utility_items() -> void:
	var items := _shop.generate_inventory(2, [])
	var has_heart := false
	var has_refresh := false
	for item in items:
		if item.item_type == ShopItem.ItemType.EXTRA_HEART:
			has_heart = true
		if item.item_type == ShopItem.ItemType.PACK_REFRESH:
			has_refresh = true
	assert_bool(has_heart).is_true()
	assert_bool(has_refresh).is_true()


func test_generate_inventory_resets_refresh_count() -> void:
	_shop.refresh_count = 5
	_shop.generate_inventory(2, [])
	assert_int(_shop.refresh_count).is_equal(0)


# -- purchase_item --

func test_purchase_item_deducts_coins() -> void:
	_coins.earn_coins(200)
	var items := _shop.generate_inventory(2, [])
	var item := items[0]
	var cost := item.cost
	var result := _shop.purchase_item(item)
	assert_bool(result).is_true()
	assert_int(_coins.get_balance()).is_equal(200 - cost)


func test_purchase_item_marks_sold() -> void:
	_coins.earn_coins(200)
	var items := _shop.generate_inventory(2, [])
	var item := items[0]
	_shop.purchase_item(item)
	assert_bool(item.is_sold).is_true()


func test_purchase_insufficient_coins_fails() -> void:
	# Don't earn any coins
	var items := _shop.generate_inventory(2, [])
	var item := items[0]
	var result := _shop.purchase_item(item)
	assert_bool(result).is_false()
	assert_bool(item.is_sold).is_false()


func test_purchase_already_sold_fails() -> void:
	_coins.earn_coins(500)
	var items := _shop.generate_inventory(2, [])
	var item := items[0]
	_shop.purchase_item(item)
	# Try to buy it again
	var result := _shop.purchase_item(item)
	assert_bool(result).is_false()


# -- refresh_shop --

func test_refresh_shop_costs_coins() -> void:
	_coins.earn_coins(200)
	var cost := _shop.get_refresh_cost()
	var result := _shop.refresh_shop(2, [])
	assert_bool(result).is_true()
	assert_int(_coins.get_balance()).is_equal(200 - cost)


func test_refresh_cost_increases() -> void:
	var first_cost := _shop.get_refresh_cost()
	_coins.earn_coins(500)
	_shop.refresh_shop(2, [])
	var second_cost := _shop.get_refresh_cost()
	assert_int(second_cost).is_greater(first_cost)


func test_refresh_insufficient_coins_fails() -> void:
	var result := _shop.refresh_shop(2, [])
	assert_bool(result).is_false()
