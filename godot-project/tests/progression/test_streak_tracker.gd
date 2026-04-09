## Tests for StreakTracker — daily play streak tracking.
extends GdUnitTestSuite

var _tracker: StreakTracker


func before_test() -> void:
	_tracker = StreakTracker.new()


# -- record_first_day --

func test_record_first_day_sets_streak_to_one() -> void:
	_tracker.record_today()
	assert_int(_tracker.current_streak).is_equal(1)


func test_record_first_day_sets_longest() -> void:
	_tracker.record_today()
	assert_int(_tracker.longest_streak).is_equal(1)


func test_record_first_day_sets_last_play_date() -> void:
	_tracker.record_today()
	assert_bool(_tracker.last_play_date.length() > 0).is_true()


# -- consecutive_days --

func test_consecutive_days_increment() -> void:
	# Simulate consecutive days by manipulating internal state
	# Day 1
	_tracker.current_streak = 0
	_tracker.last_play_date = ""
	_tracker.record_today()
	assert_int(_tracker.current_streak).is_equal(1)

	# Simulate yesterday by setting last_play_date to yesterday
	var yesterday_unix := Time.get_unix_time_from_system() - 86400.0
	var dt := Time.get_datetime_dict_from_unix_time(int(yesterday_unix))
	_tracker.last_play_date = "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]

	_tracker.record_today()
	assert_int(_tracker.current_streak).is_equal(2)


func test_consecutive_days_longest_tracked() -> void:
	# First day
	_tracker.record_today()
	# Set last_play_date to yesterday to simulate consecutive
	var yesterday_unix := Time.get_unix_time_from_system() - 86400.0
	var dt := Time.get_datetime_dict_from_unix_time(int(yesterday_unix))
	_tracker.last_play_date = "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]
	_tracker.record_today()
	assert_int(_tracker.longest_streak).is_equal(2)


# -- same day no double count --

func test_same_day_no_double_count() -> void:
	_tracker.record_today()
	_tracker.record_today()
	assert_int(_tracker.current_streak).is_equal(1)


# -- broken streak --

func test_missed_day_breaks_streak() -> void:
	_tracker.current_streak = 5
	_tracker.longest_streak = 5
	# Set last_play_date to 3 days ago (not consecutive)
	var three_days_ago := Time.get_unix_time_from_system() - 86400.0 * 3.0
	var dt := Time.get_datetime_dict_from_unix_time(int(three_days_ago))
	_tracker.last_play_date = "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]

	_tracker.record_today()
	assert_int(_tracker.current_streak).is_equal(1)
	assert_int(_tracker.longest_streak).is_equal(5)


func test_check_streak_broken_no_play_yet() -> void:
	assert_bool(_tracker.check_streak_broken()).is_false()


func test_check_streak_broken_after_gap() -> void:
	var three_days_ago := Time.get_unix_time_from_system() - 86400.0 * 3.0
	var dt := Time.get_datetime_dict_from_unix_time(int(three_days_ago))
	_tracker.last_play_date = "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]
	assert_bool(_tracker.check_streak_broken()).is_true()


# -- serialization --

func test_to_dict() -> void:
	_tracker.record_today()
	var dict := _tracker.to_dict()
	assert_int(dict["current_streak"]).is_equal(1)
	assert_int(dict["longest_streak"]).is_equal(1)
	assert_bool(dict["last_play_date"].length() > 0).is_true()


func test_from_dict_round_trip() -> void:
	_tracker.current_streak = 7
	_tracker.longest_streak = 14
	_tracker.last_play_date = "2026-04-09"
	var dict := _tracker.to_dict()
	var restored := StreakTracker.from_dict(dict)
	assert_int(restored.current_streak).is_equal(7)
	assert_int(restored.longest_streak).is_equal(14)
	assert_str(restored.last_play_date).is_equal("2026-04-09")
