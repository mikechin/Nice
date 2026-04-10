## DailyGoalManager — Tests load_today(), check_completion(), complete_daily().
extends GdUnitTestSuite

var sentence_db: SentenceDatabase
var manager: DailyGoalManager


func before_test() -> void:
	sentence_db = SentenceDatabase.new()
	var sentences: Array[Dictionary] = [
		{
			"id": "daily_001",
			"sentence": "我是学生",
			"meaning": "I am a student",
			"characters": ["我", "是", "学", "生"],
			"hsk_level": 2,
			"character_count": 4,
			"grammar_pattern": "SVO",
		},
		{
			"id": "daily_002",
			"sentence": "他很好",
			"meaning": "He is fine",
			"characters": ["他", "很", "好"],
			"hsk_level": 2,
			"character_count": 3,
			"grammar_pattern": "SVO",
		},
	] as Array[Dictionary]
	sentence_db.load_from_array(sentences)
	manager = DailyGoalManager.new(sentence_db)


func test_load_today_returns_sentence() -> void:
	var sentence := manager.load_today(2)
	assert_bool(sentence.is_empty()).is_false()
	assert_bool(sentence.has("sentence")).is_true()


func test_load_today_no_db_returns_empty() -> void:
	var no_db_manager := DailyGoalManager.new(null)
	var sentence := no_db_manager.load_today(2)
	assert_bool(sentence.is_empty()).is_true()


func test_check_completion_with_sufficient_chars() -> void:
	manager.load_today(2)
	# Provide enough characters for any sentence in the database
	var chars := {"我": 2, "是": 2, "学": 2, "生": 2, "他": 2, "很": 2, "好": 2}
	assert_bool(manager.check_completion(chars)).is_true()


func test_check_completion_with_insufficient_chars() -> void:
	manager.load_today(2)
	# Only one character -- not enough for any 3+ character sentence
	var chars := {"我": 1}
	assert_bool(manager.check_completion(chars)).is_false()


func test_check_completion_empty_sentence_returns_false() -> void:
	# Don't call load_today -- today_sentence stays empty
	var no_db_manager := DailyGoalManager.new(null)
	var chars := {"我": 1, "很": 1, "好": 1}
	assert_bool(no_db_manager.check_completion(chars)).is_false()


func test_complete_daily_returns_rewards() -> void:
	manager.load_today(2)
	var result := manager.complete_daily(["我", "是", "学", "生"])
	assert_bool(result.has("score")).is_true()
	assert_bool(result.has("reward_coins")).is_true()
	assert_int(result["reward_coins"]).is_equal(DailyGoalManager.DAILY_REWARD_COINS)


func test_complete_daily_twice_returns_empty() -> void:
	manager.load_today(2)
	manager.complete_daily(["我", "是", "学", "生"])
	var second := manager.complete_daily(["我", "是", "学", "生"])
	assert_bool(second.is_empty()).is_true()


func test_complete_daily_sets_is_completed() -> void:
	manager.load_today(2)
	assert_bool(manager.is_completed).is_false()
	manager.complete_daily(["我", "是", "学", "生"])
	assert_bool(manager.is_completed).is_true()
