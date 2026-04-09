## AchievementData — Tests check_completion(), get_progress(), from_dict().
extends GdUnitTestSuite

var achievement: AchievementData
var sample_dict: Dictionary


func before_test() -> void:
	achievement = AchievementData.new()
	achievement.achievement_id = "mastery_50"
	achievement.title = "Scholar"
	achievement.description = "Master 50 characters"
	achievement.category = AchievementData.AchievementCategory.MASTERY
	achievement.icon_id = "icon_scholar"
	achievement.requirement_value = 50
	achievement.reward_coins = 200
	achievement.is_hidden = false

	sample_dict = {
		"achievement_id": "streak_30",
		"title": "Monthly Warrior",
		"description": "Maintain a 30-day streak",
		"category": AchievementData.AchievementCategory.STREAK,
		"icon_id": "icon_streak",
		"requirement_value": 30,
		"reward_coins": 500,
		"is_hidden": true,
	}


func test_check_completion_true_when_met() -> void:
	assert_bool(achievement.check_completion(50)).is_true()


func test_check_completion_true_when_exceeded() -> void:
	assert_bool(achievement.check_completion(100)).is_true()


func test_check_completion_false_when_below() -> void:
	assert_bool(achievement.check_completion(25)).is_false()


func test_check_completion_false_at_zero() -> void:
	assert_bool(achievement.check_completion(0)).is_false()


func test_get_progress_at_half() -> void:
	var pct := achievement.get_progress(25)
	assert_float(pct).is_equal_approx(0.5, 0.01)


func test_get_progress_clamped_at_one() -> void:
	var pct := achievement.get_progress(100)
	assert_float(pct).is_equal(1.0)


func test_get_progress_at_zero() -> void:
	var pct := achievement.get_progress(0)
	assert_float(pct).is_equal(0.0)


func test_get_progress_zero_requirement() -> void:
	var ad := AchievementData.new()
	ad.requirement_value = 0
	assert_float(ad.get_progress(5)).is_equal(1.0)


func test_from_dict_sets_all_fields() -> void:
	var ad := AchievementData.from_dict(sample_dict)
	assert_str(ad.achievement_id).is_equal("streak_30")
	assert_str(ad.title).is_equal("Monthly Warrior")
	assert_str(ad.description).is_equal("Maintain a 30-day streak")
	assert_int(ad.category).is_equal(AchievementData.AchievementCategory.STREAK)
	assert_str(ad.icon_id).is_equal("icon_streak")
	assert_int(ad.requirement_value).is_equal(30)
	assert_int(ad.reward_coins).is_equal(500)
	assert_bool(ad.is_hidden).is_true()


func test_from_dict_defaults_on_empty() -> void:
	var ad := AchievementData.from_dict({})
	assert_str(ad.achievement_id).is_equal("")
	assert_str(ad.title).is_equal("")
	assert_int(ad.requirement_value).is_equal(0)
	assert_int(ad.reward_coins).is_equal(0)
	assert_bool(ad.is_hidden).is_false()


func test_to_dict_round_trip() -> void:
	var dict := achievement.to_dict()
	var restored := AchievementData.from_dict(dict)
	assert_str(restored.achievement_id).is_equal(achievement.achievement_id)
	assert_str(restored.title).is_equal(achievement.title)
	assert_int(restored.requirement_value).is_equal(achievement.requirement_value)
	assert_int(restored.reward_coins).is_equal(achievement.reward_coins)
