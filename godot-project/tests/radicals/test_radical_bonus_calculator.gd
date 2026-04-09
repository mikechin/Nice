## RadicalBonusCalculator — Tests calculate_passive_drops(), get_bonus_multiplier().
extends GdUnitTestSuite

var rad_db: RadicalDatabase
var calc: RadicalBonusCalculator


func before_test() -> void:
	rad_db = RadicalDatabase.new()
	var radicals: Array[RadicalData] = []
	radicals.append(RadicalData.from_dict({
		"radical": "氵", "meaning": "water", "rarity_tier": "common",
		"shop_cost": 50, "characters": ["海", "河", "湖", "泪"],
		"display_name": "Water",
	}))
	radicals.append(RadicalData.from_dict({
		"radical": "火", "meaning": "fire", "rarity_tier": "rare",
		"shop_cost": 100, "characters": ["烤", "灯"],
		"display_name": "Fire",
	}))
	radicals.append(RadicalData.from_dict({
		"radical": "金", "meaning": "gold", "rarity_tier": "epic",
		"shop_cost": 200, "characters": ["银", "钱", "铁"],
		"display_name": "Gold",
	}))
	rad_db.load_from_array(radicals)
	calc = RadicalBonusCalculator.new(rad_db)


func test_get_bonus_multiplier_common() -> void:
	assert_float(calc.get_bonus_multiplier("common")).is_equal(1.0)


func test_get_bonus_multiplier_rare() -> void:
	assert_float(calc.get_bonus_multiplier("rare")).is_equal(1.5)


func test_get_bonus_multiplier_epic() -> void:
	assert_float(calc.get_bonus_multiplier("epic")).is_equal(2.0)


func test_get_bonus_multiplier_unknown_defaults_to_1() -> void:
	assert_float(calc.get_bonus_multiplier("mythical")).is_equal(1.0)


func test_passive_drops_returns_array() -> void:
	var equipped: Array[String] = ["氵"]
	var drops := calc.calculate_passive_drops(equipped, "海")
	# Result is always an array (may be empty due to RNG)
	assert_bool(drops is Array).is_true()


func test_passive_drops_empty_when_no_radicals_equipped() -> void:
	var equipped: Array[String] = []
	var drops := calc.calculate_passive_drops(equipped, "海")
	assert_int(drops.size()).is_equal(0)


func test_passive_drops_empty_when_character_not_in_family() -> void:
	var equipped: Array[String] = ["火"]
	# "海" is not in fire radical's family
	var drops := calc.calculate_passive_drops(equipped, "海")
	assert_int(drops.size()).is_equal(0)


func test_passive_drops_null_db_returns_empty() -> void:
	var no_db_calc := RadicalBonusCalculator.new(null)
	var equipped: Array[String] = ["氵"]
	var drops := no_db_calc.calculate_passive_drops(equipped, "海")
	assert_int(drops.size()).is_equal(0)
