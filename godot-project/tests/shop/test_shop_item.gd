## ShopItem — Tests create_radical(), to_dict().
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
