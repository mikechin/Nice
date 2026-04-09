## Tests for EconomyScaler — reward scaling by HSK level, combo, and boss rewards.
extends GdUnitTestSuite

var _scaler: EconomyScaler


func before_test() -> void:
	_scaler = EconomyScaler.new()


# -- tile multiplier by level --

func test_tile_multiplier_hsk2() -> void:
	assert_int(_scaler.get_tile_multiplier(2)).is_equal(1)


func test_tile_multiplier_hsk3() -> void:
	assert_int(_scaler.get_tile_multiplier(3)).is_equal(1)


func test_tile_multiplier_hsk4() -> void:
	assert_int(_scaler.get_tile_multiplier(4)).is_equal(2)


func test_tile_multiplier_hsk5() -> void:
	assert_int(_scaler.get_tile_multiplier(5)).is_equal(3)


func test_tile_multiplier_unknown_level_default() -> void:
	assert_int(_scaler.get_tile_multiplier(1)).is_equal(1)


# -- combo tile bonus --

func test_combo_tile_bonus_zero_combo() -> void:
	assert_int(_scaler.get_combo_tile_bonus(0, 2)).is_equal(0)


func test_combo_tile_bonus_at_ten() -> void:
	# combo=10 passes threshold 10 -> bonus=1, multiplier=1 (HSK2) -> 1
	assert_int(_scaler.get_combo_tile_bonus(10, 2)).is_equal(1)


func test_combo_tile_bonus_at_twenty() -> void:
	# combo=20 passes thresholds 10,20 -> bonus=2, multiplier=1 (HSK2) -> 2
	assert_int(_scaler.get_combo_tile_bonus(20, 2)).is_equal(2)


func test_combo_tile_bonus_at_fifty() -> void:
	# combo=50 passes thresholds 10,20,50 -> bonus=3, multiplier=1 (HSK2) -> 3
	assert_int(_scaler.get_combo_tile_bonus(50, 2)).is_equal(3)


func test_combo_tile_bonus_hsk5_multiplied() -> void:
	# combo=10 passes threshold 10 -> bonus=1, multiplier=3 (HSK5) -> 3
	assert_int(_scaler.get_combo_tile_bonus(10, 5)).is_equal(3)


func test_combo_tile_bonus_high_combo_hsk5() -> void:
	# combo=50 passes all 3 thresholds -> bonus=3, multiplier=3 (HSK5) -> 9
	assert_int(_scaler.get_combo_tile_bonus(50, 5)).is_equal(9)


func test_combo_tile_bonus_below_first_threshold() -> void:
	assert_int(_scaler.get_combo_tile_bonus(5, 5)).is_equal(0)


# -- word drop eligibility --

func test_word_drop_below_min_level() -> void:
	var card := CharacterData.from_dict({"character": "好", "hsk_level": 2})
	assert_bool(_scaler.should_drop_word(3, card)).is_false()


func test_word_drop_no_db_always_false() -> void:
	var card := CharacterData.from_dict({"character": "好", "hsk_level": 4})
	# No word database was provided in _init
	assert_bool(_scaler.should_drop_word(4, card)).is_false()


# -- boss reward multiplier --

func test_boss_reward_hsk2() -> void:
	assert_float(_scaler.get_boss_reward_multiplier(2)).is_equal(1.0)


func test_boss_reward_hsk5() -> void:
	assert_float(_scaler.get_boss_reward_multiplier(5)).is_equal(3.0)


func test_boss_reward_unknown_level() -> void:
	assert_float(_scaler.get_boss_reward_multiplier(1)).is_equal(1.0)
