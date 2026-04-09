## BossRoundManager — Tests generate_boss_round(), submit_answer(), get_boss_type_name().
extends GdUnitTestSuite

var sentence_db: SentenceDatabase
var manager: BossRoundManager


func before_test() -> void:
	sentence_db = SentenceDatabase.new()
	var sentences: Array[Dictionary] = [
		{
			"id": "s_001",
			"sentence": "我很好",
			"meaning": "I am fine",
			"characters": ["我", "很", "好"],
			"hsk_level": 2,
			"tile_count": 3,
			"grammar_pattern": "SVO",
		},
		{
			"id": "s_002",
			"sentence": "他是学生",
			"meaning": "He is a student",
			"characters": ["他", "是", "学", "生"],
			"hsk_level": 2,
			"tile_count": 4,
			"grammar_pattern": "SVO",
		},
	] as Array[Dictionary]
	sentence_db.load_from_array(sentences)
	manager = BossRoundManager.new(sentence_db)


func test_generate_boss_round_with_matching_tiles() -> void:
	var tiles := {"我": 2, "很": 1, "好": 1, "他": 1, "是": 1, "学": 1, "生": 1}
	var challenge := manager.generate_boss_round(2, tiles)
	assert_bool(challenge.is_empty()).is_false()
	assert_bool(challenge.has("boss_type")).is_true()


func test_generate_boss_round_no_tiles_returns_empty() -> void:
	var tiles := {"猫": 1}
	var challenge := manager.generate_boss_round(2, tiles)
	assert_bool(challenge.is_empty()).is_true()


func test_generate_boss_round_no_db_returns_empty() -> void:
	var no_db_manager := BossRoundManager.new(null)
	var tiles := {"我": 1, "很": 1, "好": 1}
	var challenge := no_db_manager.generate_boss_round(2, tiles)
	assert_bool(challenge.is_empty()).is_true()


func test_get_boss_type_name_fill_blank() -> void:
	manager.current_boss_type = BossRoundManager.BossType.FILL_BLANK
	assert_str(manager.get_boss_type_name()).is_equal("Fill in the Blank")


func test_get_boss_type_name_scramble() -> void:
	manager.current_boss_type = BossRoundManager.BossType.SCRAMBLE
	assert_str(manager.get_boss_type_name()).is_equal("Unscramble")


func test_get_boss_type_name_free_build() -> void:
	manager.current_boss_type = BossRoundManager.BossType.FREE_BUILD
	assert_str(manager.get_boss_type_name()).is_equal("Free Build")


func test_submit_answer_scramble_correct() -> void:
	# Set up a scramble challenge manually
	manager.current_boss_type = BossRoundManager.BossType.SCRAMBLE
	manager.current_challenge = {
		"type": "scramble",
		"original": "我很好",
		"meaning": "I am fine",
		"sentence_data": {"tile_count": 3},
	}
	var result := manager.submit_answer("我很好")
	assert_bool(result["correct"]).is_true()
	assert_int(result["score"]).is_greater(0)


func test_submit_answer_scramble_incorrect() -> void:
	manager.current_boss_type = BossRoundManager.BossType.SCRAMBLE
	manager.current_challenge = {
		"type": "scramble",
		"original": "我很好",
		"meaning": "I am fine",
		"sentence_data": {"tile_count": 3},
	}
	var result := manager.submit_answer("好很我")
	assert_bool(result["correct"]).is_false()
	assert_int(result["score"]).is_equal(0)
