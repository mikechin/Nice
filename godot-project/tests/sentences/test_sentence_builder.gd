## Tests for SentenceBuilder — character placement, removal, and scoring.
extends GdUnitTestSuite

var _builder: SentenceBuilder


func before_test() -> void:
	_builder = SentenceBuilder.new()
	_builder.set_available_chars({"好": 3, "大": 2, "人": 1})


# -- place_char --

func test_place_char_adds_to_sentence() -> void:
	var result := _builder.place_char("好")
	assert_bool(result).is_true()
	assert_int(_builder.get_placed_count()).is_equal(1)


func test_place_char_decrements_available() -> void:
	_builder.place_char("好")
	assert_int(_builder.available_chars.get("好", 0)).is_equal(2)


func test_place_char_builds_sentence() -> void:
	_builder.place_char("好")
	_builder.place_char("人")
	assert_str(_builder.get_current_sentence()).is_equal("好人")


func test_place_char_unavailable_fails() -> void:
	var result := _builder.place_char("X")
	assert_bool(result).is_false()
	assert_int(_builder.get_placed_count()).is_equal(0)


func test_place_char_exhausted_fails() -> void:
	_builder.place_char("人")  # Only 1 available
	var result := _builder.place_char("人")
	assert_bool(result).is_false()


func test_place_char_at_position() -> void:
	_builder.place_char("大")
	_builder.place_char("人")
	_builder.place_char("好", 1)  # Insert between 大 and 人
	assert_str(_builder.get_current_sentence()).is_equal("大好人")


# -- remove_char --

func test_remove_char_returns_character() -> void:
	_builder.place_char("好")
	var removed := _builder.remove_char(0)
	assert_str(removed).is_equal("好")


func test_remove_char_restores_available() -> void:
	_builder.place_char("好")
	_builder.remove_char(0)
	assert_int(_builder.available_chars.get("好", 0)).is_equal(3)


func test_remove_char_decrements_placed() -> void:
	_builder.place_char("好")
	_builder.place_char("大")
	_builder.remove_char(0)
	assert_int(_builder.get_placed_count()).is_equal(1)


func test_remove_char_invalid_position_returns_empty() -> void:
	var removed := _builder.remove_char(5)
	assert_str(removed).is_equal("")


func test_remove_char_negative_position_returns_empty() -> void:
	var removed := _builder.remove_char(-1)
	assert_str(removed).is_equal("")


# -- clear_sentence --

func test_clear_sentence_empties_placed() -> void:
	_builder.place_char("好")
	_builder.place_char("大")
	_builder.clear_sentence()
	assert_int(_builder.get_placed_count()).is_equal(0)
	assert_str(_builder.get_current_sentence()).is_equal("")


func test_clear_sentence_restores_all_available() -> void:
	_builder.place_char("好")
	_builder.place_char("大")
	_builder.clear_sentence()
	assert_int(_builder.available_chars.get("好", 0)).is_equal(3)
	assert_int(_builder.available_chars.get("大", 0)).is_equal(2)


# -- max_length_enforced --

func test_max_length_enforced() -> void:
	_builder.max_length = 2
	_builder.set_available_chars({"好": 10})
	_builder.place_char("好")
	_builder.place_char("好")
	var result := _builder.place_char("好")
	assert_bool(result).is_false()
	assert_int(_builder.get_placed_count()).is_equal(2)


# -- calculate_score --

func test_score_basic_chars() -> void:
	_builder.place_char("好")
	_builder.place_char("大")
	var score := _builder.calculate_score("好大", [], [])
	# 2 chars * 10 base + 2 * 5 length bonus = 30
	assert_int(score).is_equal(30)


func test_score_with_srs_rare_bonus() -> void:
	_builder.place_char("好")
	var score := _builder.calculate_score("好", ["好"], [])
	# 1 * 10 base + 1 * 25 rare + 1 * 5 length = 40
	assert_int(score).is_equal(40)


func test_score_with_radical_bonus() -> void:
	_builder.place_char("好")
	var score := _builder.calculate_score("好", [], ["好"])
	# 1 * 10 base + 1 * 15 radical + 1 * 5 length = 30
	assert_int(score).is_equal(30)
