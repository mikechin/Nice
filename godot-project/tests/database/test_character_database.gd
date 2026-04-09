## Tests for CharacterDatabase — in-memory index of HSK characters.
extends GdUnitTestSuite

var db: CharacterDatabase
var _test_chars: Array[CharacterData]


func before_test() -> void:
	db = CharacterDatabase.new()
	_test_chars = _make_test_characters()
	db.load_from_array(_test_chars)


func _make_test_characters() -> Array[CharacterData]:
	var chars: Array[CharacterData] = []

	chars.append(CharacterData.from_dict({
		"character": "好",
		"pinyin": "hǎo",
		"tone": 3,
		"meaning": "good",
		"hsk_level": 2,
		"radicals": ["女", "子"],
		"components": ["女", "子"],
		"is_radical": false,
		"frequency_rank": 50,
	}))

	chars.append(CharacterData.from_dict({
		"character": "她",
		"pinyin": "tā",
		"tone": 1,
		"meaning": "she",
		"hsk_level": 2,
		"radicals": ["女", "也"],
		"components": ["女", "也"],
		"is_radical": false,
		"frequency_rank": 30,
	}))

	chars.append(CharacterData.from_dict({
		"character": "大",
		"pinyin": "dà",
		"tone": 4,
		"meaning": "big",
		"hsk_level": 2,
		"radicals": ["大"],
		"components": ["大"],
		"is_radical": true,
		"frequency_rank": 10,
	}))

	chars.append(CharacterData.from_dict({
		"character": "学",
		"pinyin": "xué",
		"tone": 2,
		"meaning": "to study",
		"hsk_level": 3,
		"radicals": ["子"],
		"components": ["子", "冖"],
		"is_radical": false,
		"frequency_rank": 40,
	}))

	chars.append(CharacterData.from_dict({
		"character": "吗",
		"pinyin": "ma",
		"tone": 0,
		"meaning": "question particle",
		"hsk_level": 2,
		"radicals": ["口", "马"],
		"components": ["口", "马"],
		"is_radical": false,
		"frequency_rank": 60,
	}))

	chars.append(CharacterData.from_dict({
		"character": "妈",
		"pinyin": "mā",
		"tone": 1,
		"meaning": "mother",
		"hsk_level": 2,
		"radicals": ["女", "马"],
		"components": ["女", "马"],
		"is_radical": false,
		"frequency_rank": 80,
	}))

	return chars


# -- load_from_array --

func test_load_from_array_sets_loaded() -> void:
	assert_bool(db.is_loaded()).is_true()


func test_load_from_array_correct_count() -> void:
	assert_int(db.get_count()).is_equal(6)


# -- get_character --

func test_get_character_by_string() -> void:
	var cd := db.get_character("好")
	assert_bool(cd != null).is_true()
	assert_str(cd.character).is_equal("好")
	assert_str(cd.meaning).is_equal("good")


func test_get_character_nonexistent_returns_null() -> void:
	var cd := db.get_character("龙")
	assert_bool(cd == null).is_true()


func test_has_character() -> void:
	assert_bool(db.has_character("好")).is_true()
	assert_bool(db.has_character("龙")).is_false()


# -- get_by_hsk_level --

func test_get_by_hsk_level_2() -> void:
	var level_2 := db.get_by_hsk_level(2)
	# 好, 她, 大, 吗, 妈 are all level 2
	assert_int(level_2.size()).is_equal(5)


func test_get_by_hsk_level_3() -> void:
	var level_3 := db.get_by_hsk_level(3)
	# Only 学 is level 3
	assert_int(level_3.size()).is_equal(1)


func test_get_by_hsk_level_nonexistent() -> void:
	var level_9 := db.get_by_hsk_level(9)
	assert_int(level_9.size()).is_equal(0)


# -- get_same_radical_characters --

func test_get_same_radical_characters() -> void:
	# 好 has radicals [女, 子]. 她 has 女, 学 has 子, 妈 has 女.
	var same := db.get_same_radical_characters("好")
	assert_int(same.size()).is_greater_equal(3)
	var chars: Array[String] = []
	for cd in same:
		chars.append(cd.character)
	assert_bool("她" in chars).is_true()
	assert_bool("学" in chars).is_true()
	assert_bool("妈" in chars).is_true()


func test_get_same_radical_excludes_self() -> void:
	var same := db.get_same_radical_characters("好")
	var chars: Array[String] = []
	for cd in same:
		chars.append(cd.character)
	assert_bool("好" not in chars).is_true()


func test_get_same_radical_nonexistent() -> void:
	var same := db.get_same_radical_characters("龙")
	assert_int(same.size()).is_equal(0)


# -- get_same_tone_characters --

func test_get_same_tone_characters() -> void:
	# 她 and 妈 both have tone 1
	var same := db.get_same_tone_characters("她")
	var chars: Array[String] = []
	for cd in same:
		chars.append(cd.character)
	assert_bool("妈" in chars).is_true()


func test_get_same_tone_excludes_self() -> void:
	var same := db.get_same_tone_characters("她")
	var chars: Array[String] = []
	for cd in same:
		chars.append(cd.character)
	assert_bool("她" not in chars).is_true()


# -- get_by_tone --

func test_get_by_tone() -> void:
	var tone_1 := db.get_by_tone(1)
	# 她 (tone 1) and 妈 (tone 1)
	assert_int(tone_1.size()).is_equal(2)


# -- get_by_radical --

func test_get_by_radical() -> void:
	var with_nv := db.get_by_radical("女")
	# 好, 她, 妈 all contain 女
	assert_int(with_nv.size()).is_equal(3)


func test_get_by_radical_nonexistent() -> void:
	var result := db.get_by_radical("龍")
	assert_int(result.size()).is_equal(0)


# -- get_similar_pinyin_characters --

func test_get_similar_pinyin_characters() -> void:
	# 吗 has pinyin "ma" and 妈 has pinyin "mā" -- both base pinyin "ma"
	var similar := db.get_similar_pinyin_characters("吗")
	var chars: Array[String] = []
	for cd in similar:
		chars.append(cd.character)
	assert_bool("妈" in chars).is_true()


# -- get_random_same_level --

func test_get_random_same_level_correct_count() -> void:
	var randoms := db.get_random_same_level("好", 2)
	assert_int(randoms.size()).is_equal(2)


func test_get_random_same_level_excludes_self() -> void:
	var randoms := db.get_random_same_level("好", 5)
	var chars: Array[String] = []
	for cd in randoms:
		chars.append(cd.character)
	assert_bool("好" not in chars).is_true()


# -- get_all_radicals --

func test_get_all_radicals() -> void:
	var radicals := db.get_all_radicals()
	assert_bool("女" in radicals).is_true()
	assert_bool("子" in radicals).is_true()
	assert_bool("大" in radicals).is_true()
	assert_bool("马" in radicals).is_true()


# -- get_hsk_levels --

func test_get_hsk_levels() -> void:
	var levels := db.get_hsk_levels()
	assert_int(levels.size()).is_equal(2)
	assert_int(levels[0]).is_equal(2)
	assert_int(levels[1]).is_equal(3)


# -- get_character_count_for_level --

func test_get_character_count_for_level() -> void:
	assert_int(db.get_character_count_for_level(2)).is_equal(5)
	assert_int(db.get_character_count_for_level(3)).is_equal(1)
	assert_int(db.get_character_count_for_level(9)).is_equal(0)
