## RadicalData — Tests from_dict(), to_dict() round-trip, rarity checks, get_character_count().
extends GdUnitTestSuite

var sample_dict: Dictionary


func before_test() -> void:
	sample_dict = {
		"radical": "氵",
		"meaning": "water",
		"rarity_tier": "rare",
		"shop_cost": 80,
		"characters": ["海", "河", "湖", "泪"],
		"display_name": "Water Radical",
	}


func test_from_dict_sets_all_fields() -> void:
	var rd := RadicalData.from_dict(sample_dict)
	assert_str(rd.radical).is_equal("氵")
	assert_str(rd.meaning).is_equal("water")
	assert_str(rd.rarity_tier).is_equal("rare")
	assert_int(rd.shop_cost).is_equal(80)
	assert_str(rd.display_name).is_equal("Water Radical")
	assert_int(rd.characters.size()).is_equal(4)


func test_from_dict_defaults_on_empty() -> void:
	var rd := RadicalData.from_dict({})
	assert_str(rd.radical).is_equal("")
	assert_str(rd.rarity_tier).is_equal("common")
	assert_int(rd.shop_cost).is_equal(50)
	assert_int(rd.characters.size()).is_equal(0)


func test_to_dict_round_trip() -> void:
	var rd := RadicalData.from_dict(sample_dict)
	var exported := rd.to_dict()
	var restored := RadicalData.from_dict(exported)
	assert_str(restored.radical).is_equal(rd.radical)
	assert_str(restored.meaning).is_equal(rd.meaning)
	assert_str(restored.rarity_tier).is_equal(rd.rarity_tier)
	assert_int(restored.shop_cost).is_equal(rd.shop_cost)
	assert_int(restored.characters.size()).is_equal(rd.characters.size())


func test_is_epic_true() -> void:
	var rd := RadicalData.from_dict({"rarity_tier": "epic"})
	assert_bool(rd.is_epic()).is_true()


func test_is_epic_false_for_rare() -> void:
	var rd := RadicalData.from_dict(sample_dict)
	assert_bool(rd.is_epic()).is_false()


func test_is_rare_true() -> void:
	var rd := RadicalData.from_dict(sample_dict)
	assert_bool(rd.is_rare()).is_true()


func test_is_rare_false_for_common() -> void:
	var rd := RadicalData.from_dict({"rarity_tier": "common"})
	assert_bool(rd.is_rare()).is_false()


func test_get_character_count() -> void:
	var rd := RadicalData.from_dict(sample_dict)
	assert_int(rd.get_character_count()).is_equal(4)
