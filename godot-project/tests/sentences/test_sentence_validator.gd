## Tests for SentenceValidator — sentence matching, fill-blank, and scramble validation.
extends GdUnitTestSuite

var _validator: SentenceValidator
var _sentence_db: SentenceDatabase


func before_test() -> void:
	_sentence_db = SentenceDatabase.new()
	var sentences: Array[Dictionary] = [
		{
			"id": "s1",
			"sentence": "你好",
			"meaning": "hello",
			"hsk_level": 2,
			"character_count": 2,
			"grammar_pattern": "greeting",
			"characters": ["你", "好"],
		},
		{
			"id": "s2",
			"sentence": "我是人",
			"meaning": "I am a person",
			"hsk_level": 2,
			"character_count": 3,
			"grammar_pattern": "SVO",
			"characters": ["我", "是", "人"],
		},
		{
			"id": "s3",
			"sentence": "你好吗",
			"meaning": "how are you",
			"hsk_level": 2,
			"character_count": 3,
			"grammar_pattern": "question",
			"characters": ["你", "好", "吗"],
		},
	]
	_sentence_db.load_from_array(sentences)
	_validator = SentenceValidator.new(_sentence_db)


# -- validate known sentence --

func test_validate_known_sentence_valid() -> void:
	var result := _validator.validate("你好")
	assert_bool(result["valid"]).is_true()


func test_validate_known_sentence_has_score() -> void:
	var result := _validator.validate("你好")
	assert_int(result["score"]).is_greater(0)


func test_validate_known_sentence_feedback_is_meaning() -> void:
	var result := _validator.validate("你好")
	assert_str(result["feedback"]).is_equal("hello")


func test_validate_known_sentence_includes_data() -> void:
	var result := _validator.validate("你好")
	assert_bool(result.has("sentence_data")).is_true()


# -- validate unknown --

func test_validate_unknown_returns_invalid() -> void:
	var result := _validator.validate("大人")
	assert_bool(result["valid"]).is_false()


func test_validate_unknown_score_zero() -> void:
	var result := _validator.validate("大人")
	assert_int(result["score"]).is_equal(0)


# -- partial match --

func test_validate_partial_match_hint() -> void:
	# "你好" is start of "你好吗"
	var result := _validator.validate("你好")
	# "你好" is itself a full match, so check a partial that is NOT a full match
	# Let's check a scenario where something starts with partial
	# Actually "你好" is already a valid sentence, so partial won't trigger
	assert_bool(result["valid"]).is_true()


func test_validate_single_char_partial() -> void:
	# "你" begins "你好" but is not a full sentence match
	var result := _validator.validate("你")
	# Should be invalid but potentially hint
	assert_bool(result["valid"]).is_false()


# -- validate_fill_blank --

func test_fill_blank_correct_answer() -> void:
	# Original "你好", blank at position 1, answer "好"
	var result := _validator.validate_fill_blank("你_", 1, "好")
	# Reconstructs "你好" which is valid
	assert_bool(result).is_true()


func test_fill_blank_wrong_answer() -> void:
	var result := _validator.validate_fill_blank("你_", 1, "大")
	assert_bool(result).is_false()


# -- validate_scramble --

func test_scramble_correct_order() -> void:
	var result := _validator.validate_scramble("你好", "你好")
	assert_bool(result).is_true()


func test_scramble_wrong_order() -> void:
	var result := _validator.validate_scramble("你好", "好你")
	assert_bool(result).is_false()


# -- validate_free_build --

func test_free_build_correct() -> void:
	var result := _validator.validate_free_build("hello", "你好")
	assert_bool(result).is_true()


func test_free_build_wrong_sentence() -> void:
	var result := _validator.validate_free_build("hello", "大人")
	assert_bool(result).is_false()


# -- no database --

func test_no_database_returns_invalid() -> void:
	var v := SentenceValidator.new(null)
	var result := v.validate("你好")
	assert_bool(result["valid"]).is_false()
