## Tests for EconomyScaler — word drop eligibility.
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


