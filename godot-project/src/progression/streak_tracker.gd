## StreakTracker — Tracks daily play streaks.
class_name StreakTracker
extends RefCounted

var current_streak: int = 0
var longest_streak: int = 0
var last_play_date: String = ""


func record_today() -> void:
	var today := _get_today()
	if today == last_play_date:
		return  # Already recorded today

	if _is_consecutive(last_play_date, today):
		current_streak += 1
	else:
		# Streak broken — reset
		if current_streak > 0:
			SignalBus.streak_broken.emit()
		current_streak = 1

	longest_streak = maxi(longest_streak, current_streak)
	last_play_date = today
	SignalBus.streak_updated.emit(current_streak)


func check_streak_broken() -> bool:
	var today := _get_today()
	if last_play_date == "":
		return false
	return not _is_consecutive(last_play_date, today) and last_play_date != today


func get_streak() -> int:
	return current_streak


func _get_today() -> String:
	var dt := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]


func _is_consecutive(date_a: String, date_b: String) -> bool:
	if date_a == "" or date_b == "":
		return false
	# Parse dates and check if b is exactly 1 day after a
	var unix_a := Time.get_unix_time_from_datetime_string(date_a + "T00:00:00")
	var unix_b := Time.get_unix_time_from_datetime_string(date_b + "T00:00:00")
	var diff := unix_b - unix_a
	return diff > 0 and diff <= 86400


func to_dict() -> Dictionary:
	return {
		"current_streak": current_streak,
		"longest_streak": longest_streak,
		"last_play_date": last_play_date,
	}


static func from_dict(data: Dictionary) -> StreakTracker:
	var st := StreakTracker.new()
	st.current_streak = data.get("current_streak", 0)
	st.longest_streak = data.get("longest_streak", 0)
	st.last_play_date = data.get("last_play_date", "")
	return st
