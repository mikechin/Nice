## DropCalculator — Tests calculate_drops() for tiles, coins, and radical bonuses.
extends GdUnitTestSuite

var scaler: EconomyScaler
var coins: CoinManager
var rad_db: RadicalDatabase
var calc: DropCalculator
var test_char: CharacterData


func before_test() -> void:
	scaler = EconomyScaler.new()
	coins = CoinManager.new()
	rad_db = RadicalDatabase.new()

	# Build a radical database with one radical containing our test character
	var rd := RadicalData.from_dict({
		"radical": "氵",
		"meaning": "water",
		"rarity_tier": "common",
		"shop_cost": 50,
		"characters": ["海", "河", "湖"],
		"display_name": "Water",
	})
	rad_db.load_from_array([rd])

	calc = DropCalculator.new(scaler, coins, rad_db)

	test_char = CharacterData.from_dict({
		"character": "海",
		"pinyin": "hǎi",
		"tone": 3,
		"meaning": "sea",
		"hsk_level": 2,
	})


func test_drops_contain_tiles() -> void:
	var equipped: Array[String] = []
	var drops := calc.calculate_drops(test_char, SrsEnums.LootRarity.COMMON, 0, 2, equipped)
	assert_bool(drops.has("tiles")).is_true()
	assert_bool(drops["tiles"].size() > 0).is_true()


func test_drops_contain_coins() -> void:
	var equipped: Array[String] = []
	var drops := calc.calculate_drops(test_char, SrsEnums.LootRarity.COMMON, 0, 2, equipped)
	assert_bool(drops.has("coins")).is_true()
	assert_int(drops["coins"]).is_greater(0)


func test_tiles_contain_character() -> void:
	var equipped: Array[String] = []
	var drops := calc.calculate_drops(test_char, SrsEnums.LootRarity.COMMON, 0, 2, equipped)
	var tiles: Array = drops["tiles"]
	assert_bool(tiles.has("海")).is_true()


func test_radical_bonus_when_equipped() -> void:
	var equipped: Array[String] = ["氵"]
	var drops := calc.calculate_drops(test_char, SrsEnums.LootRarity.COMMON, 0, 2, equipped)
	assert_bool(drops.has("radical_bonus")).is_true()
	var bonus: Dictionary = drops["radical_bonus"]
	assert_str(bonus.get("radical", "")).is_equal("氵")
	assert_int(bonus.get("bonus_coins", 0)).is_equal(5)


func test_no_radical_bonus_when_not_equipped() -> void:
	var equipped: Array[String] = []
	var drops := calc.calculate_drops(test_char, SrsEnums.LootRarity.COMMON, 0, 2, equipped)
	var bonus: Dictionary = drops.get("radical_bonus", {})
	assert_bool(bonus.is_empty()).is_true()


func test_higher_combo_increases_tiles() -> void:
	var equipped: Array[String] = []
	var drops_low := calc.calculate_drops(test_char, SrsEnums.LootRarity.COMMON, 0, 2, equipped)
	var drops_high := calc.calculate_drops(test_char, SrsEnums.LootRarity.COMMON, 50, 2, equipped)
	assert_bool(drops_high["tiles"].size() >= drops_low["tiles"].size()).is_true()


func test_about_to_forget_rarity_gives_more_coins() -> void:
	var equipped: Array[String] = []
	var drops_common := calc.calculate_drops(test_char, SrsEnums.LootRarity.COMMON, 0, 2, equipped)
	var drops_forget := calc.calculate_drops(test_char, SrsEnums.LootRarity.ABOUT_TO_FORGET, 0, 2, equipped)
	assert_bool(drops_forget["coins"] > drops_common["coins"]).is_true()
