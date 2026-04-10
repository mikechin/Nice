## Tests for RadicalActivator — radical activation detection and bonus calculation.
extends GdUnitTestSuite

var _activator: RadicalActivator
var _radical_db: RadicalDatabase
var _radical_mgr: RadicalManager
var _test_card: CharacterData


func before_test() -> void:
	# Build radical database with known radical-to-character mappings
	_radical_db = RadicalDatabase.new()
	var radicals: Array[RadicalData] = []
	radicals.append(RadicalData.from_dict({
		"radical": "女",
		"meaning": "woman",
		"rarity_tier": "common",
		"shop_cost": 50,
		"characters": ["好", "妈", "她"],
	}))
	radicals.append(RadicalData.from_dict({
		"radical": "子",
		"meaning": "child",
		"rarity_tier": "rare",
		"shop_cost": 100,
		"characters": ["好", "学", "字"],
	}))
	radicals.append(RadicalData.from_dict({
		"radical": "火",
		"meaning": "fire",
		"rarity_tier": "epic",
		"shop_cost": 200,
		"characters": ["烧", "灯"],
	}))
	_radical_db.load_from_array(radicals)

	# Set up radical manager with some owned and equipped
	_radical_mgr = RadicalManager.new()
	_radical_mgr.purchase_radical("女")
	_radical_mgr.purchase_radical("子")
	_radical_mgr.purchase_radical("火")
	_radical_mgr.equip_radical("女")
	_radical_mgr.equip_radical("子")

	_activator = RadicalActivator.new(_radical_db, _radical_mgr)

	# Test card: 好 contains radicals 女 and 子
	_test_card = CharacterData.from_dict({
		"character": "好",
		"pinyin": "hǎo",
		"tone": 3,
		"meaning": "good",
		"hsk_level": 2,
		"radicals": ["女", "子"],
	})


# -- no match --

func test_no_match_returns_not_activated() -> void:
	# Card with no matching equipped radicals
	var card := CharacterData.from_dict({
		"character": "大",
		"meaning": "big",
		"radicals": ["大"],
	})
	var result := _activator.check_activation(card)
	assert_bool(result["activated"]).is_false()


func test_no_match_unequipped_radical() -> void:
	# "火" is owned but NOT equipped
	var card := CharacterData.from_dict({
		"character": "烧",
		"meaning": "burn",
		"radicals": ["火"],
	})
	var result := _activator.check_activation(card)
	assert_bool(result["activated"]).is_false()


# -- match equipped --

func test_match_equipped_returns_activated() -> void:
	var result := _activator.check_activation(_test_card)
	assert_bool(result["activated"]).is_true()


func test_match_equipped_has_radical() -> void:
	var result := _activator.check_activation(_test_card)
	assert_bool(result.has("radical")).is_true()
	# First matching radical should be returned
	assert_bool(result["radical"] in ["女", "子"]).is_true()


func test_match_equipped_has_bonus_coins() -> void:
	var result := _activator.check_activation(_test_card)
	assert_int(result["bonus_coins"]).is_greater(0)


func test_match_equipped_mode_is_recognition() -> void:
	var result := _activator.check_activation(_test_card)
	assert_str(result["mode"]).is_equal("recognition")


func test_match_equipped_all_matching_returned() -> void:
	var result := _activator.check_activation(_test_card)
	var matching: Array = result["all_matching"]
	# Both 女 and 子 are equipped and present in 好
	assert_bool("女" in matching).is_true()
	assert_bool("子" in matching).is_true()


# -- get_matching_radicals --

func test_get_matching_radicals_with_matches() -> void:
	var matching := _activator.get_matching_radicals("好")
	assert_int(matching.size()).is_equal(2)


func test_get_matching_radicals_no_matches() -> void:
	var matching := _activator.get_matching_radicals("大")
	assert_int(matching.size()).is_equal(0)


# -- calculate_radical_bonus --

func test_bonus_common_radical() -> void:
	var bonus := _activator.calculate_radical_bonus("女", _test_card, 0)
	assert_int(bonus).is_equal(RadicalActivator.BASE_RADICAL_BONUS)


func test_bonus_rare_radical() -> void:
	var bonus := _activator.calculate_radical_bonus("子", _test_card, 0)
	var expected := roundi(float(RadicalActivator.BASE_RADICAL_BONUS) * RadicalActivator.RARE_RADICAL_MULT)
	assert_int(bonus).is_equal(expected)


func test_bonus_epic_radical() -> void:
	_radical_mgr.equip_radical("火")
	var card := CharacterData.from_dict({"character": "烧", "meaning": "burn"})
	var bonus := _activator.calculate_radical_bonus("火", card, 0)
	var expected := roundi(float(RadicalActivator.BASE_RADICAL_BONUS) * RadicalActivator.EPIC_RADICAL_MULT)
	assert_int(bonus).is_equal(expected)


# -- can_trigger_attach --

func test_attach_mode_with_radical_base() -> void:
	var radical_card := CharacterData.from_dict({
		"character": "女",
		"meaning": "woman",
		"is_radical": true,
	})
	assert_bool(_activator.can_trigger_attach(radical_card)).is_true()


func test_attach_mode_non_radical_card() -> void:
	assert_bool(_activator.can_trigger_attach(_test_card)).is_false()


# -- null dependencies --

func test_null_databases_returns_not_activated() -> void:
	var null_activator := RadicalActivator.new(null, null)
	var result := null_activator.check_activation(_test_card)
	assert_bool(result["activated"]).is_false()


func test_null_db_matching_radicals_empty() -> void:
	var null_activator := RadicalActivator.new(null, null)
	var matching := null_activator.get_matching_radicals("好")
	assert_int(matching.size()).is_equal(0)
