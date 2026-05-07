## Tests for AnswerGenerator — answer layout generation for four-directional swipe.
extends GdUnitTestSuite

var _gen: AnswerGenerator
var _char_db: CharacterDatabase
var _test_card: CharacterData


func before_test() -> void:
	# Build a small character database for distractor generation
	_char_db = CharacterDatabase.new()
	var chars: Array[CharacterData] = []
	chars.append(CharacterData.from_dict({
		"character": "好", "pinyin": "hǎo", "tone": 3,
		"meaning": "good", "hsk_level": 2, "radicals": ["女", "子"],
	}))
	chars.append(CharacterData.from_dict({
		"character": "大", "pinyin": "dà", "tone": 4,
		"meaning": "big", "hsk_level": 2, "radicals": ["大"],
	}))
	chars.append(CharacterData.from_dict({
		"character": "小", "pinyin": "xiǎo", "tone": 3,
		"meaning": "small", "hsk_level": 2, "radicals": ["小"],
	}))
	chars.append(CharacterData.from_dict({
		"character": "人", "pinyin": "rén", "tone": 2,
		"meaning": "person", "hsk_level": 2, "radicals": ["人"],
	}))
	chars.append(CharacterData.from_dict({
		"character": "女", "pinyin": "nǚ", "tone": 3,
		"meaning": "woman", "hsk_level": 2, "radicals": ["女"],
	}))
	_char_db.load_from_array(chars)

	_gen = AnswerGenerator.new(_char_db)
	_test_card = chars[0]  # 好


# -- generate_answers --

func test_generate_answers_has_four_directions() -> void:
	var result := _gen.generate_answers(_test_card, "meaning")
	assert_bool(result.has("up")).is_true()
	assert_bool(result.has("down")).is_true()
	assert_bool(result.has("left")).is_true()
	assert_bool(result.has("right")).is_true()


func test_generate_answers_has_correct_direction() -> void:
	var result := _gen.generate_answers(_test_card, "meaning")
	assert_bool(result.has("correct_direction")).is_true()
	var dir: String = result["correct_direction"]
	assert_bool(dir in ["up", "down", "left", "right"]).is_true()


func test_generate_answers_correct_answer_present() -> void:
	var result := _gen.generate_answers(_test_card, "meaning")
	var correct_dir: String = result["correct_direction"]
	assert_str(result[correct_dir]).is_equal("good")


func test_generate_answers_correct_answer_field() -> void:
	var result := _gen.generate_answers(_test_card, "meaning")
	assert_str(result["correct_answer"]).is_equal("good")


func test_generate_answers_challenge_type_stored() -> void:
	var result := _gen.generate_answers(_test_card, "pinyin")
	assert_str(result["challenge_type"]).is_equal("pinyin")


# -- all answers unique --

func test_all_answers_unique_meaning() -> void:
	var result := _gen.generate_answers(_test_card, "meaning")
	var answers: Array[String] = []
	for dir in ["up", "down", "left", "right"]:
		answers.append(result[dir])
	# Check no duplicates
	var seen := {}
	for a in answers:
		assert_bool(seen.has(a)).is_false()
		seen[a] = true


func test_all_answers_unique_character() -> void:
	var result := _gen.generate_answers(_test_card, "character")
	var answers: Array[String] = []
	for dir in ["up", "down", "left", "right"]:
		answers.append(result[dir])
	var seen := {}
	for a in answers:
		assert_bool(seen.has(a)).is_false()
		seen[a] = true


# -- correct answer in result --

func test_correct_answer_meaning() -> void:
	var result := _gen.generate_answers(_test_card, "meaning")
	var correct_dir: String = result["correct_direction"]
	assert_str(result[correct_dir]).is_equal(_test_card.meaning)


func test_correct_answer_character() -> void:
	var result := _gen.generate_answers(_test_card, "character")
	var correct_dir: String = result["correct_direction"]
	assert_str(result[correct_dir]).is_equal(_test_card.character)


func test_correct_answer_pinyin() -> void:
	var result := _gen.generate_answers(_test_card, "pinyin")
	var correct_dir: String = result["correct_direction"]
	assert_str(result[correct_dir]).is_equal(_test_card.pinyin)


# -- tone challenge --

func test_tone_challenge_has_correct_tone() -> void:
	var result := _gen.generate_answers(_test_card, "tone")
	var correct_dir: String = result["correct_direction"]
	# tone=3 -> "ˇ (3rd)"
	assert_str(result[correct_dir]).is_equal("ˇ (3rd)")


# -- no database fallback --

func test_no_database_uses_fallback() -> void:
	var gen_no_db := AnswerGenerator.new(null)
	var result := gen_no_db.generate_answers(_test_card, "meaning")
	# Should still have 4 directions, correct answer filled
	assert_bool(result.has("up")).is_true()
	assert_bool(result.has("correct_direction")).is_true()


# -- distractor backstop: every direction is filled, even with a tiny DB --

func test_tiny_db_still_fills_four_directions() -> void:
	# Regression: with no same-radical / same-level candidates, the previous
	# implementation left some directions unset (blank answer slots in the UI).
	var tiny_db := CharacterDatabase.new()
	var solo: Array[CharacterData] = [_test_card]
	tiny_db.load_from_array(solo)
	var gen := AnswerGenerator.new(tiny_db)

	var result := gen.generate_answers(_test_card, "meaning")
	for dir in ["up", "down", "left", "right"]:
		var v: String = result.get(dir, "")
		assert_str(v).is_not_equal("")


func test_tiny_db_distractors_are_unique() -> void:
	var tiny_db := CharacterDatabase.new()
	var solo: Array[CharacterData] = [_test_card]
	tiny_db.load_from_array(solo)
	var gen := AnswerGenerator.new(tiny_db)

	var result := gen.generate_answers(_test_card, "character")
	var seen := {}
	for dir in ["up", "down", "left", "right"]:
		var v: String = result[dir]
		assert_bool(seen.has(v)).is_false()
		seen[v] = true


func test_no_db_fallback_strings_are_unique() -> void:
	# Ensures the no-DB safety net still produces 4 distinct slots.
	var gen_no_db := AnswerGenerator.new(null)
	var result := gen_no_db.generate_answers(_test_card, "meaning")
	var seen := {}
	for dir in ["up", "down", "left", "right"]:
		var v: String = result[dir]
		assert_bool(seen.has(v)).is_false()
		seen[v] = true
