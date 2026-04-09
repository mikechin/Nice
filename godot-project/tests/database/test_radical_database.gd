## Tests for RadicalDatabase — in-memory index of radicals.
extends GdUnitTestSuite

var db: RadicalDatabase
var _test_radicals: Array[RadicalData]


func before_test() -> void:
	db = RadicalDatabase.new()
	_test_radicals = _make_test_radicals()
	db.load_from_array(_test_radicals)


func _make_test_radicals() -> Array[RadicalData]:
	var radicals: Array[RadicalData] = []

	radicals.append(RadicalData.from_dict({
		"radical": "女",
		"meaning": "woman",
		"rarity_tier": "common",
		"shop_cost": 50,
		"characters": ["好", "她", "妈"],
		"display_name": "Woman",
	}))

	radicals.append(RadicalData.from_dict({
		"radical": "子",
		"meaning": "child",
		"rarity_tier": "common",
		"shop_cost": 50,
		"characters": ["好", "学", "字"],
		"display_name": "Child",
	}))

	radicals.append(RadicalData.from_dict({
		"radical": "口",
		"meaning": "mouth",
		"rarity_tier": "rare",
		"shop_cost": 150,
		"characters": ["吗", "吃", "叫"],
		"display_name": "Mouth",
	}))

	radicals.append(RadicalData.from_dict({
		"radical": "火",
		"meaning": "fire",
		"rarity_tier": "epic",
		"shop_cost": 300,
		"characters": ["烧", "灯"],
		"display_name": "Fire",
	}))

	return radicals


# -- load_from_array --

func test_load_from_array_sets_loaded() -> void:
	assert_bool(db.is_loaded()).is_true()


func test_load_from_array_correct_count() -> void:
	assert_int(db.get_count()).is_equal(4)


# -- get_radical --

func test_get_radical_by_string() -> void:
	var rd := db.get_radical("女")
	assert_bool(rd != null).is_true()
	assert_str(rd.radical).is_equal("女")
	assert_str(rd.meaning).is_equal("woman")


func test_get_radical_nonexistent_returns_null() -> void:
	var rd := db.get_radical("龍")
	assert_bool(rd == null).is_true()


func test_has_radical() -> void:
	assert_bool(db.has_radical("女")).is_true()
	assert_bool(db.has_radical("龍")).is_false()


# -- get_radicals_for_character (reverse lookup) --

func test_get_radicals_for_character() -> void:
	# 好 is in both 女 and 子
	var radicals := db.get_radicals_for_character("好")
	assert_int(radicals.size()).is_equal(2)
	assert_bool("女" in radicals).is_true()
	assert_bool("子" in radicals).is_true()


func test_get_radicals_for_character_single() -> void:
	# 吗 is only in 口
	var radicals := db.get_radicals_for_character("吗")
	assert_int(radicals.size()).is_equal(1)
	assert_str(radicals[0]).is_equal("口")


func test_get_radicals_for_unknown_character() -> void:
	var radicals := db.get_radicals_for_character("龙")
	assert_int(radicals.size()).is_equal(0)


# -- get_characters_for_radical --

func test_get_characters_for_radical() -> void:
	var chars := db.get_characters_for_radical("女")
	assert_int(chars.size()).is_equal(3)
	assert_bool("好" in chars).is_true()
	assert_bool("她" in chars).is_true()
	assert_bool("妈" in chars).is_true()


func test_get_characters_for_unknown_radical() -> void:
	var chars := db.get_characters_for_radical("龍")
	assert_int(chars.size()).is_equal(0)


# -- get_by_rarity --

func test_get_by_rarity_common() -> void:
	var commons := db.get_by_rarity("common")
	assert_int(commons.size()).is_equal(2)


func test_get_by_rarity_rare() -> void:
	var rares := db.get_by_rarity("rare")
	assert_int(rares.size()).is_equal(1)


func test_get_by_rarity_epic() -> void:
	var epics := db.get_by_rarity("epic")
	assert_int(epics.size()).is_equal(1)
	assert_str(epics[0].radical).is_equal("火")


func test_get_by_rarity_nonexistent() -> void:
	var legendary := db.get_by_rarity("legendary")
	assert_int(legendary.size()).is_equal(0)


# -- character_has_radical --

func test_character_has_radical_true() -> void:
	assert_bool(db.character_has_radical("好", "女")).is_true()


func test_character_has_radical_false() -> void:
	assert_bool(db.character_has_radical("好", "口")).is_false()


func test_character_has_radical_unknown_char() -> void:
	assert_bool(db.character_has_radical("龙", "女")).is_false()


# -- get_shop_cost --

func test_get_shop_cost() -> void:
	assert_int(db.get_shop_cost("女")).is_equal(50)
	assert_int(db.get_shop_cost("口")).is_equal(150)
	assert_int(db.get_shop_cost("火")).is_equal(300)


func test_get_shop_cost_unknown() -> void:
	assert_int(db.get_shop_cost("龍")).is_equal(0)


# -- RadicalData helpers --

func test_radical_data_is_epic() -> void:
	var rd := db.get_radical("火")
	assert_bool(rd.is_epic()).is_true()
	assert_bool(rd.is_rare()).is_false()


func test_radical_data_is_rare() -> void:
	var rd := db.get_radical("口")
	assert_bool(rd.is_rare()).is_true()
	assert_bool(rd.is_epic()).is_false()


func test_radical_data_get_character_count() -> void:
	var rd := db.get_radical("女")
	assert_int(rd.get_character_count()).is_equal(3)
