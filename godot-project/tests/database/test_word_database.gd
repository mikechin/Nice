## WordDatabase — Tests load_from_array(), get_word(), can_fuse(), get_fusion_result(), get_words_for_character().
extends GdUnitTestSuite

var db: WordDatabase
var test_words: Array[Dictionary]


func before_test() -> void:
	db = WordDatabase.new()
	test_words = [
		{"word": "电影", "meaning": "movie", "characters": ["电", "影"], "hsk_level": 2},
		{"word": "学生", "meaning": "student", "characters": ["学", "生"], "hsk_level": 2},
		{"word": "电话", "meaning": "phone", "characters": ["电", "话"], "hsk_level": 2},
	] as Array[Dictionary]
	db.load_from_array(test_words)


func test_load_from_array_sets_loaded() -> void:
	assert_bool(db.is_loaded()).is_true()


func test_load_from_array_correct_count() -> void:
	assert_int(db.get_count()).is_equal(3)


func test_get_word_found() -> void:
	var result := db.get_word("电影")
	assert_str(result.get("meaning", "")).is_equal("movie")


func test_get_word_not_found_returns_empty() -> void:
	var result := db.get_word("不存在")
	assert_bool(result.is_empty()).is_true()


func test_can_fuse_forward() -> void:
	assert_bool(db.can_fuse("电", "影")).is_true()


func test_can_fuse_reverse() -> void:
	assert_bool(db.can_fuse("影", "电")).is_true()


func test_can_fuse_false() -> void:
	assert_bool(db.can_fuse("学", "电")).is_false()


func test_get_fusion_result_forward() -> void:
	var result := db.get_fusion_result("电", "影")
	assert_str(result.get("word", "")).is_equal("电影")


func test_get_fusion_result_reverse() -> void:
	var result := db.get_fusion_result("影", "电")
	assert_str(result.get("word", "")).is_equal("电影")


func test_get_fusion_result_no_match() -> void:
	var result := db.get_fusion_result("学", "电")
	assert_bool(result.is_empty()).is_true()


func test_get_words_for_character_multiple() -> void:
	var results := db.get_words_for_character("电")
	assert_int(results.size()).is_equal(2)


func test_get_words_for_character_single() -> void:
	var results := db.get_words_for_character("影")
	assert_int(results.size()).is_equal(1)


func test_get_words_for_character_none() -> void:
	var results := db.get_words_for_character("猫")
	assert_int(results.size()).is_equal(0)
