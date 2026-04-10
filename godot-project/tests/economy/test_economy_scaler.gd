## Tests for EconomyScaler — word drop eligibility and boss reward multipliers.
extends GdUnitTestSuite

var _scaler: EconomyScaler


func before_test() -> void:
	_scaler = EconomyScaler.new()


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
