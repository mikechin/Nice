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
	defs.append(a1)

	tracker.register_definitions(defs)


func test_register_definitions_sets_count() -> void:
	assert_int(tracker.get_total_count()).is_equal(1)


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


func test_completion_percentage() -> void:
	tracker.set_progress("mastery_10", 15)
	tracker.check_all()
	var pct := tracker.get_completion_percentage()
	# 1 out of 1 completed
	assert_float(pct).is_equal_approx(1.0, 0.01)
