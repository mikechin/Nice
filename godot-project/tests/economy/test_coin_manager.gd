## Tests for CoinManager — coin earning, spending, and value calculation.
extends GdUnitTestSuite

var _coins: CoinManager


func before_test() -> void:
	_coins = CoinManager.new()


# -- earn_coins --

func test_earn_coins_adds_to_balance() -> void:
	_coins.earn_coins(50)
	assert_int(_coins.get_balance()).is_equal(50)


func test_earn_coins_accumulates() -> void:
	_coins.earn_coins(30)
	_coins.earn_coins(20)
	assert_int(_coins.get_balance()).is_equal(50)


# -- spend_coins --

func test_spend_coins_success() -> void:
	_coins.earn_coins(100)
	var result := _coins.spend_coins(40)
	assert_bool(result).is_true()
	assert_int(_coins.get_balance()).is_equal(60)


func test_spend_coins_exact_balance() -> void:
	_coins.earn_coins(50)
	var result := _coins.spend_coins(50)
	assert_bool(result).is_true()
	assert_int(_coins.get_balance()).is_equal(0)


func test_spend_coins_insufficient() -> void:
	_coins.earn_coins(10)
	var result := _coins.spend_coins(50)
	assert_bool(result).is_false()
	assert_int(_coins.get_balance()).is_equal(10)


func test_spend_coins_zero_balance() -> void:
	var result := _coins.spend_coins(1)
	assert_bool(result).is_false()
	assert_int(_coins.get_balance()).is_equal(0)


# -- calculate_coin_value --

func test_calculate_coin_value_common() -> void:
	var value := _coins.calculate_coin_value(
		SrsEnums.LootRarity.COMMON, 0, 2, false, 1.0
	)
	# base=10, HSK2 bonus=0, rarity=1.0, combo_mult=1.0, radical=1.0 -> 10
	assert_int(value).is_equal(10)


func test_calculate_coin_value_learning_rarity() -> void:
	var value := _coins.calculate_coin_value(
		SrsEnums.LootRarity.LEARNING, 0, 2, false, 1.0
	)
	# base=10, rarity=1.5 -> 15
	assert_int(value).is_equal(15)


func test_calculate_coin_value_about_to_forget() -> void:
	var value := _coins.calculate_coin_value(
		SrsEnums.LootRarity.ABOUT_TO_FORGET, 0, 2, false, 1.0
	)
	# base=10, rarity=4.0 -> 40
	assert_int(value).is_equal(40)


func test_calculate_coin_value_new_card() -> void:
	var value := _coins.calculate_coin_value(
		SrsEnums.LootRarity.NEW_CARD, 0, 2, false, 1.0
	)
	# base=10, rarity=2.0 -> 20
	assert_int(value).is_equal(20)


func test_calculate_coin_value_hsk5_bonus() -> void:
	var value := _coins.calculate_coin_value(
		SrsEnums.LootRarity.COMMON, 0, 5, false, 1.0
	)
	# base=10+20=30, rarity=1.0 -> 30
	assert_int(value).is_equal(30)


func test_calculate_coin_value_with_radical_bonus() -> void:
	var value := _coins.calculate_coin_value(
		SrsEnums.LootRarity.COMMON, 0, 2, true, 1.0
	)
	# base=10, rarity=1.0, radical=1.5 -> 15
	assert_int(value).is_equal(15)


func test_calculate_coin_value_with_combo_multiplier() -> void:
	var value := _coins.calculate_coin_value(
		SrsEnums.LootRarity.COMMON, 0, 2, false, 2.0
	)
	# base=10, rarity=1.0, combo_mult=2.0 -> 20
	assert_int(value).is_equal(20)


func test_calculate_coin_value_minimum_is_one() -> void:
	# Even with zeros, the minimum coin value should be 1
	var value := _coins.calculate_coin_value(
		SrsEnums.LootRarity.COMMON, 0, 2, false, 0.001
	)
	assert_int(value).is_greater_equal(1)


# -- set_balance --

func test_set_balance() -> void:
	_coins.set_balance(999)
	assert_int(_coins.get_balance()).is_equal(999)
