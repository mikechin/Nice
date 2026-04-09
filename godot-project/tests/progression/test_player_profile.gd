## Tests for PlayerProfile — mastery tracking, level-up, and serialization.
extends GdUnitTestSuite

var _profile: PlayerProfile


func before_test() -> void:
	_profile = PlayerProfile.new()


# -- update_mastery --

func test_update_mastery_sets_percentage() -> void:
	_profile.update_mastery(2, 40, 100)
	assert_float(_profile.get_mastery_for_level(2)).is_equal(0.4)


func test_update_mastery_full() -> void:
	_profile.update_mastery(2, 100, 100)
	assert_float(_profile.get_mastery_for_level(2)).is_equal(1.0)


func test_update_mastery_zero_total() -> void:
	_profile.update_mastery(2, 0, 0)
	assert_float(_profile.get_mastery_for_level(2)).is_equal(0.0)


func test_update_mastery_multiple_levels() -> void:
	_profile.update_mastery(2, 80, 100)
	_profile.update_mastery(3, 30, 100)
	assert_float(_profile.get_mastery_for_level(2)).is_equal(0.8)
	assert_float(_profile.get_mastery_for_level(3)).is_equal(0.3)


# -- check_level_up --

func test_check_level_up_at_threshold() -> void:
	_profile.hsk_level = 2
	_profile.update_mastery(2, 90, 100)  # 0.9 >= 0.85 threshold
	var result := _profile.check_level_up()
	assert_bool(result).is_true()
	assert_int(_profile.hsk_level).is_equal(3)


func test_check_level_up_below_threshold() -> void:
	_profile.hsk_level = 2
	_profile.update_mastery(2, 50, 100)  # 0.5 < 0.85
	var result := _profile.check_level_up()
	assert_bool(result).is_false()
	assert_int(_profile.hsk_level).is_equal(2)


func test_check_level_up_at_exactly_threshold() -> void:
	_profile.hsk_level = 2
	_profile.update_mastery(2, 85, 100)  # 0.85 >= 0.85
	var result := _profile.check_level_up()
	assert_bool(result).is_true()
	assert_int(_profile.hsk_level).is_equal(3)


func test_check_level_up_max_level_no_advance() -> void:
	_profile.hsk_level = 5  # MAX_HSK_LEVEL
	_profile.update_mastery(5, 100, 100)
	var result := _profile.check_level_up()
	assert_bool(result).is_false()
	assert_int(_profile.hsk_level).is_equal(5)


# -- get_mastery_for_level --

func test_get_mastery_unset_level_returns_zero() -> void:
	assert_float(_profile.get_mastery_for_level(4)).is_equal(0.0)


# -- get_overall_mastery --

func test_overall_mastery_empty() -> void:
	assert_float(_profile.get_overall_mastery()).is_equal(0.0)


func test_overall_mastery_average() -> void:
	_profile.update_mastery(2, 80, 100)  # 0.8
	_profile.update_mastery(3, 60, 100)  # 0.6
	# Average = (0.8 + 0.6) / 2 = 0.7
	assert_float(_profile.get_overall_mastery()).is_equal_approx(0.7, 0.001)


# -- get_accuracy --

func test_accuracy_no_reviews() -> void:
	assert_float(_profile.get_accuracy()).is_equal(0.0)


func test_accuracy_calculation() -> void:
	_profile.total_cards_reviewed = 10
	_profile.total_correct_answers = 8
	assert_float(_profile.get_accuracy()).is_equal_approx(0.8, 0.001)


# -- serialization --

func test_serialization_to_dict() -> void:
	_profile.hsk_level = 3
	_profile.total_runs_completed = 15
	_profile.update_mastery(2, 90, 100)
	var dict := _profile.to_dict()
	assert_int(dict["hsk_level"]).is_equal(3)
	assert_int(dict["total_runs_completed"]).is_equal(15)


func test_serialization_round_trip() -> void:
	_profile.hsk_level = 4
	_profile.total_runs_completed = 20
	_profile.total_play_time_seconds = 3600.0
	_profile.total_cards_reviewed = 500
	_profile.total_correct_answers = 400
	_profile.update_mastery(2, 95, 100)
	_profile.update_mastery(3, 70, 100)

	var dict := _profile.to_dict()
	var restored := PlayerProfile.from_dict(dict)

	assert_int(restored.hsk_level).is_equal(4)
	assert_int(restored.total_runs_completed).is_equal(20)
	assert_float(restored.total_play_time_seconds).is_equal(3600.0)
	assert_int(restored.total_cards_reviewed).is_equal(500)
	assert_int(restored.total_correct_answers).is_equal(400)


func test_from_dict_defaults() -> void:
	var restored := PlayerProfile.from_dict({})
	assert_int(restored.hsk_level).is_equal(2)
	assert_int(restored.total_runs_completed).is_equal(0)
