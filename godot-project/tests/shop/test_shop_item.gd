## ShopItem — Tests create_radical(), create_utility_tile(), create_extra_heart(), to_dict().
extends GdUnitTestSuite

var test_radical: RadicalData


func before_test() -> void:
	test_radical = RadicalData.from_dict({
		"radical": "氵",
		"meaning": "water",
		"rarity_tier": "rare",
		"shop_cost": 80,
		"characters": ["海", "河"],
		"display_name": "Water Radical",
	})


func test_create_radical_type() -> void:
	var item := ShopItem.create_radical(test_radical)
	assert_int(item.item_type).is_equal(ShopItem.ItemType.RADICAL)


func test_create_radical_id_and_cost() -> void:
	var item := ShopItem.create_radical(test_radical)
	assert_str(item.item_id).is_equal("radical_氵")
	assert_int(item.cost).is_equal(80)
	assert_str(item.display_name).is_equal("Water Radical")


func test_create_radical_data_contains_radical_key() -> void:
	var item := ShopItem.create_radical(test_radical)
	assert_str(item.data.get("radical", "")).is_equal("氵")
	assert_str(item.data.get("rarity_tier", "")).is_equal("rare")


func test_create_utility_tile() -> void:
	var item := ShopItem.create_utility_tile("的", 15)
	assert_int(item.item_type).is_equal(ShopItem.ItemType.UTILITY_TILE)
	assert_str(item.item_id).is_equal("tile_的")
	assert_int(item.cost).is_equal(15)
	assert_str(item.data.get("character", "")).is_equal("的")


func test_create_extra_heart() -> void:
	var item := ShopItem.create_extra_heart()
	assert_int(item.item_type).is_equal(ShopItem.ItemType.EXTRA_HEART)
	assert_str(item.item_id).is_equal("extra_heart")
	assert_int(item.cost).is_equal(50)


func test_create_extra_heart_custom_cost() -> void:
	var item := ShopItem.create_extra_heart(100)
	assert_int(item.cost).is_equal(100)


func test_to_dict_contains_all_fields() -> void:
	var item := ShopItem.create_radical(test_radical)
	var dict := item.to_dict()
	assert_bool(dict.has("item_type")).is_true()
	assert_bool(dict.has("item_id")).is_true()
	assert_bool(dict.has("display_name")).is_true()
	assert_bool(dict.has("description")).is_true()
	assert_bool(dict.has("cost")).is_true()
	assert_bool(dict.has("data")).is_true()
	assert_bool(dict.has("is_sold")).is_true()


func test_to_dict_values_match() -> void:
	var item := ShopItem.create_utility_tile("了", 20)
	var dict := item.to_dict()
	assert_str(dict["item_id"]).is_equal("tile_了")
	assert_int(dict["cost"]).is_equal(20)
	assert_bool(dict["is_sold"]).is_false()
