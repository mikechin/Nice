## Tests for SentenceDatabase — sentence queries, daily/weekly selection, boss building.
extends GdUnitTestSuite

var db: SentenceDatabase
var _test_sentences: Array[Dictionary]
var _test_trials: Array[Dictionary]


func before_test() -> void:
	db = SentenceDatabase.new()
	_test_sentences = _make_test_sentences()
	_test_trials = _make_test_trials()
	db.load_from_array(_test_sentences, _test_trials)


func _make_test_sentences() -> Array[Dictionary]:
	return [
		{
			"id": "s1",
			"chinese": "你好",
			"english": "Hello",
			"hsk_level": 2,
			"grammar_pattern": "greeting",
			"characters": ["你", "好"],
			"character_count": 2,
		},
		{
			"id": "s2",
			"chinese": "你好吗",
			"english": "How are you?",
			"hsk_level": 2,
			"grammar_pattern": "question",
			"characters": ["你", "好", "吗"],
			"character_count": 3,
		},
		{
			"id": "s3",
			"chinese": "她很好",
			"english": "She is good",
			"hsk_level": 2,
			"grammar_pattern": "statement",
			"characters": ["她", "很", "好"],
			"character_count": 3,
		},
		{
			"id": "s4",
			"chinese": "我学中文",
			"english": "I study Chinese",
			"hsk_level": 3,
			"grammar_pattern": "SVO",
			"characters": ["我", "学", "中", "文"],
			"character_count": 4,
		},
		{
			"id": "s5",
			"chinese": "大学",
			"english": "university",
			"hsk_level": 3,
			"grammar_pattern": "compound",
			"characters": ["大", "学"],
			"character_count": 2,
		},
	]


func _make_test_trials() -> Array[Dictionary]:
	return [
		{
			"id": "t1",
			"chinese": "你好世界",
			"english": "Hello world",
			"hsk_level": 2,
			"characters": ["你", "好", "世", "界"],
			"character_count": 4,
		},
		{
			"id": "t2",
			"chinese": "学习快乐",
			"english": "Happy studying",
			"hsk_level": 3,
			"characters": ["学", "习", "快", "乐"],
			"character_count": 4,
		},
	]


# -- load_from_array --

func test_load_from_array_sets_loaded() -> void:
	assert_bool(db.is_loaded()).is_true()


func test_load_from_array_correct_count() -> void:
	assert_int(db.get_count()).is_equal(5)


# -- get_sentence --

func test_get_sentence_by_id() -> void:
	var s := db.get_sentence("s1")
	assert_str(s.get("chinese", "")).is_equal("你好")
	assert_str(s.get("english", "")).is_equal("Hello")


func test_get_sentence_nonexistent_returns_empty() -> void:
	var s := db.get_sentence("nonexistent")
	assert_int(s.size()).is_equal(0)


# -- get_sentences_for_level --

func test_get_sentences_for_level_2() -> void:
	var level_2 := db.get_sentences_for_level(2)
	assert_int(level_2.size()).is_equal(3)


func test_get_sentences_for_level_3() -> void:
	var level_3 := db.get_sentences_for_level(3)
	assert_int(level_3.size()).is_equal(2)


func test_get_sentences_for_level_nonexistent() -> void:
	var level_9 := db.get_sentences_for_level(9)
	assert_int(level_9.size()).is_equal(0)


# -- get_sentences_for_grammar --

func test_get_sentences_for_grammar() -> void:
	var greetings := db.get_sentences_for_grammar("greeting")
	assert_int(greetings.size()).is_equal(1)


func test_get_sentences_for_grammar_nonexistent() -> void:
	var result := db.get_sentences_for_grammar("nonexistent_pattern")
	assert_int(result.size()).is_equal(0)


# -- get_daily_sentence (deterministic) --

func test_daily_sentence_is_deterministic() -> void:
	var s1 := db.get_daily_sentence(2, "2026-04-09")
	var s2 := db.get_daily_sentence(2, "2026-04-09")
	assert_str(s1.get("id", "")).is_equal(s2.get("id", ""))


func test_daily_sentence_different_dates_can_differ() -> void:
	# Not guaranteed to differ, but with enough dates it should pick different entries
	var ids := {}
	for day in range(1, 30):
		var date := "2026-04-%02d" % day
		var s := db.get_daily_sentence(2, date)
		ids[s.get("id", "")] = true
	# With 3 level-2 sentences and 29 dates, we should see more than 1 distinct id
	assert_int(ids.size()).is_greater(1)


func test_daily_sentence_empty_pool_returns_empty() -> void:
	var s := db.get_daily_sentence(9, "2026-04-09")
	assert_int(s.size()).is_equal(0)


# -- get_weekly_trial (deterministic) --

func test_weekly_trial_is_deterministic() -> void:
	var t1 := db.get_weekly_trial(2, "2026-W15")
	var t2 := db.get_weekly_trial(2, "2026-W15")
	assert_str(t1.get("id", "")).is_equal(t2.get("id", ""))


func test_weekly_trial_returns_trial_data() -> void:
	var t := db.get_weekly_trial(2, "2026-W15")
	assert_bool(t.has("id")).is_true()
	assert_bool(t.has("chinese")).is_true()


# -- get_boss_sentence --

func test_boss_sentence_with_sufficient_chars() -> void:
	# Provide characters for the simplest level 2 sentence: 你好 (s1, character_count=2)
	var chars := {"你": 1, "好": 1}
	var s := db.get_boss_sentence(2, chars)
	assert_bool(s.size() > 0).is_true()
	assert_str(s.get("id", "")).is_equal("s1")


func test_boss_sentence_insufficient_chars_returns_empty() -> void:
	# No characters at all
	var s := db.get_boss_sentence(2, {})
	assert_int(s.size()).is_equal(0)


func test_boss_sentence_partial_chars() -> void:
	# Only have one of 你 -- can't build any sentence
	var chars := {"你": 1}
	var s := db.get_boss_sentence(2, chars)
	assert_int(s.size()).is_equal(0)


func test_boss_sentence_picks_simplest_buildable() -> void:
	# Provide characters for both s1 (character_count 2) and s2 (character_count 3)
	var chars := {"你": 1, "好": 1, "吗": 1}
	var s := db.get_boss_sentence(2, chars)
	# Should pick s1 first because it sorts by character_count ascending
	assert_str(s.get("id", "")).is_equal("s1")


func test_boss_sentence_nonexistent_level() -> void:
	var chars := {"你": 1, "好": 1}
	var s := db.get_boss_sentence(9, chars)
	assert_int(s.size()).is_equal(0)


# -- empty database --

func test_empty_database_not_loaded() -> void:
	var empty_db := SentenceDatabase.new()
	assert_bool(empty_db.is_loaded()).is_false()


func test_empty_database_count() -> void:
	var empty_db := SentenceDatabase.new()
	assert_int(empty_db.get_count()).is_equal(0)
