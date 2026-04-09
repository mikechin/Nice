## CharacterData — Tests from_dict(), to_dict() round-trip, get_base_pinyin(), get_card_id().
extends GdUnitTestSuite

var sample_dict: Dictionary


func before_test() -> void:
	sample_dict = {
		"character": "好",
		"pinyin": "hǎo",
		"tone": 3,
		"meaning": "good",
		"hsk_level": 2,
		"radicals": ["女", "子"],
		"components": ["女", "子"],
		"is_radical": false,
		"frequency_rank": 42,
	}


func test_from_dict_sets_all_fields() -> void:
	var cd := CharacterData.from_dict(sample_dict)
	assert_str(cd.character).is_equal("好")
	assert_str(cd.pinyin).is_equal("hǎo")
	assert_int(cd.tone).is_equal(3)
	assert_str(cd.meaning).is_equal("good")
	assert_int(cd.hsk_level).is_equal(2)
	assert_int(cd.radicals.size()).is_equal(2)
	assert_int(cd.components.size()).is_equal(2)
	assert_bool(cd.is_radical).is_false()
	assert_int(cd.frequency_rank).is_equal(42)


func test_from_dict_defaults_on_empty() -> void:
	var cd := CharacterData.from_dict({})
	assert_str(cd.character).is_equal("")
	assert_str(cd.pinyin).is_equal("")
	assert_int(cd.tone).is_equal(0)
	assert_int(cd.hsk_level).is_equal(2)
	assert_bool(cd.is_radical).is_false()


func test_to_dict_round_trip() -> void:
	var cd := CharacterData.from_dict(sample_dict)
	var exported := cd.to_dict()
	var restored := CharacterData.from_dict(exported)
	assert_str(restored.character).is_equal(cd.character)
	assert_str(restored.pinyin).is_equal(cd.pinyin)
	assert_int(restored.tone).is_equal(cd.tone)
	assert_str(restored.meaning).is_equal(cd.meaning)
	assert_int(restored.hsk_level).is_equal(cd.hsk_level)
	assert_int(restored.radicals.size()).is_equal(cd.radicals.size())
	assert_int(restored.components.size()).is_equal(cd.components.size())
	assert_bool(restored.is_radical).is_equal(cd.is_radical)
	assert_int(restored.frequency_rank).is_equal(cd.frequency_rank)


func test_get_base_pinyin_strips_third_tone() -> void:
	var cd := CharacterData.from_dict(sample_dict)
	assert_str(cd.get_base_pinyin()).is_equal("hao")


func test_get_base_pinyin_strips_first_tone() -> void:
	var cd := CharacterData.from_dict({"pinyin": "māo"})
	assert_str(cd.get_base_pinyin()).is_equal("mao")


func test_get_base_pinyin_strips_fourth_tone() -> void:
	var cd := CharacterData.from_dict({"pinyin": "dà"})
	assert_str(cd.get_base_pinyin()).is_equal("da")


func test_get_base_pinyin_no_marks_unchanged() -> void:
	var cd := CharacterData.from_dict({"pinyin": "de"})
	assert_str(cd.get_base_pinyin()).is_equal("de")


func test_get_card_id_returns_character() -> void:
	var cd := CharacterData.from_dict(sample_dict)
	assert_str(cd.get_card_id()).is_equal("好")
