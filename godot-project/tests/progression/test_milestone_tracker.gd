## MilestoneTracker — Tests register_definitions(), set_progress(), check_all(), update_from_stats().
extends GdUnitTestSuite

var tracker: MilestoneTracker
var defs: Array[AchievementData]


func before_test() -> void:
	tracker = MilestoneTracker.new()
	defs = [] as Array[AchievementData]

	var a1 := AchievementData.new()
	a1.achievement_id = "mastery_10"
	a1.title = "First Steps"
	a1.requirement_value = 10
	a1.reward_coins = 50
	defs.append(a1)

	var a2 := AchievementData.new()
	a2.achievement_id = "streak_7"
	a2.title = "One Week Streak"
	a2.requirement_value = 7
	a2.reward_coins = 100
	defs.append(a2)

	var a3 := AchievementData.new()
	a3.achievement_id = "combo_10"
	a3.title = "Combo King"
	a3.requirement_value = 10
	a3.reward_coins = 75
	defs.append(a3)

	tracker.register_definitions(defs)


func test_register_definitions_sets_count() -> void:
	assert_int(tracker.get_total_count()).is_equal(3)


func test_set_progress_and_get_progress() -> void:
	tracker.set_progress("mastery_10", 5)
	assert_int(tracker.get_progress("mastery_10")).is_equal(5)


func test_increment_progress() -> void:
	tracker.set_progress("mastery_10", 5)
	tracker.increment_progress("mastery_10", 3)
	assert_int(tracker.get_progress("mastery_10")).is_equal(8)


func test_check_all_detects_completion() -> void:
	tracker.set_progress("mastery_10", 15)
	var newly := tracker.check_all()
	assert_bool("mastery_10" in newly).is_true()
	assert_bool(tracker.is_completed("mastery_10")).is_true()


func test_check_all_skips_already_completed() -> void:
	tracker.set_progress("mastery_10", 15)
	tracker.check_all()
	# Second call should not return mastery_10 again
	var newly_again := tracker.check_all()
	assert_bool("mastery_10" in newly_again).is_false()


func test_check_all_does_not_complete_below_threshold() -> void:
	tracker.set_progress("mastery_10", 5)
	var newly := tracker.check_all()
	assert_bool("mastery_10" in newly).is_false()
	assert_bool(tracker.is_completed("mastery_10")).is_false()


func test_update_from_stats_mastery() -> void:
	var stats := {"total_characters_mastered": 12}
	var newly := tracker.update_from_stats(stats)
	assert_bool("mastery_10" in newly).is_true()


func test_update_from_stats_streak() -> void:
	var stats := {"current_streak": 7}
	var newly := tracker.update_from_stats(stats)
	assert_bool("streak_7" in newly).is_true()


func test_update_from_stats_combo() -> void:
	var stats := {"best_combo": 15}
	var newly := tracker.update_from_stats(stats)
	assert_bool("combo_10" in newly).is_true()


func test_completion_percentage() -> void:
	tracker.set_progress("mastery_10", 15)
	tracker.set_progress("streak_7", 10)
	tracker.check_all()
	var pct := tracker.get_completion_percentage()
	# 2 out of 3 completed
	assert_float(pct).is_equal_approx(2.0 / 3.0, 0.01)
