## WeeklyTrialManager — Tests submit_trial_sentence(), is_trial_complete(), get_trial_requirements().
extends GdUnitTestSuite

var manager: WeeklyTrialManager


func before_test() -> void:
	manager = WeeklyTrialManager.new(null)
	# Manually set a current trial so we don't depend on SentenceDatabase
	manager.current_trial = {
		"id": "trial_2026_W15",
		"theme": "greetings",
		"hsk_level": 2,
	}
	# Reset progress
	manager.trial_progress = {}


func test_submit_trial_sentence_increments_count() -> void:
	var result := manager.submit_trial_sentence("你好吗", ["你", "好", "吗"])
	assert_int(result["sentences_completed"]).is_equal(1)
	assert_bool(result.has("sentence_score")).is_true()
	assert_int(result["sentence_score"]).is_greater(0)


func test_submit_trial_sentence_accumulates_score() -> void:
	manager.submit_trial_sentence("你好", ["你", "好"])
	var result := manager.submit_trial_sentence("我好", ["我", "好"])
	assert_int(result["total_score"]).is_greater(result["sentence_score"])


func test_is_trial_complete_false_initially() -> void:
	assert_bool(manager.is_trial_complete()).is_false()


func test_is_trial_complete_after_enough_sentences() -> void:
	for i in range(WeeklyTrialManager.TRIAL_SENTENCES_REQUIRED):
		manager.submit_trial_sentence("句子%d" % i, ["句", "子"])
	assert_bool(manager.is_trial_complete()).is_true()


func test_get_trial_requirements_structure() -> void:
	var req := manager.get_trial_requirements()
	assert_bool(req.has("sentences_required")).is_true()
	assert_bool(req.has("sentences_completed")).is_true()
	assert_bool(req.has("reward_coins")).is_true()
	assert_int(req["sentences_required"]).is_equal(WeeklyTrialManager.TRIAL_SENTENCES_REQUIRED)
	assert_int(req["reward_coins"]).is_equal(WeeklyTrialManager.TRIAL_REWARD_COINS)


func test_get_trial_requirements_tracks_progress() -> void:
	manager.submit_trial_sentence("你好", ["你", "好"])
	var req := manager.get_trial_requirements()
	assert_int(req["sentences_completed"]).is_equal(1)


func test_submit_marks_trial_complete_flag() -> void:
	for i in range(WeeklyTrialManager.TRIAL_SENTENCES_REQUIRED):
		var result := manager.submit_trial_sentence("句%d" % i, ["句"])
		if i == WeeklyTrialManager.TRIAL_SENTENCES_REQUIRED - 1:
			assert_bool(result["trial_complete"]).is_true()
		else:
			assert_bool(result["trial_complete"]).is_false()
