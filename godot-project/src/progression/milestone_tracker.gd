## MilestoneTracker — Tracks achievement/milestone progress and unlocks.
class_name MilestoneTracker
extends RefCounted

var _completed: Dictionary = {}       # achievement_id -> completion timestamp
var _progress: Dictionary = {}        # achievement_id -> current_value
var _definitions: Array[AchievementData] = []


func register_definitions(achievements: Array[AchievementData]) -> void:
	_definitions = achievements


func get_definitions() -> Array[AchievementData]:
	return _definitions


func is_completed(achievement_id: String) -> bool:
	return achievement_id in _completed


func get_progress(achievement_id: String) -> int:
	return _progress.get(achievement_id, 0)


func set_progress(achievement_id: String, value: int) -> void:
	_progress[achievement_id] = value


func increment_progress(achievement_id: String, amount: int = 1) -> void:
	_progress[achievement_id] = _progress.get(achievement_id, 0) + amount


## Check all milestones against current progress. Returns newly completed IDs.
func check_all() -> Array[String]:
	var newly_completed: Array[String] = []
	for ad in _definitions:
		if is_completed(ad.achievement_id):
			continue
		var current := get_progress(ad.achievement_id)
		if ad.check_completion(current):
			_completed[ad.achievement_id] = Time.get_unix_time_from_system()
			newly_completed.append(ad.achievement_id)
			SignalBus.milestone_achieved.emit(ad.achievement_id)
	return newly_completed


## Update progress from game stats. Call after each session.
func update_from_stats(stats: Dictionary) -> Array[String]:
	# Map stat keys to achievement IDs
	if stats.has("total_characters_mastered"):
		set_progress("mastery_10", stats["total_characters_mastered"])
		set_progress("mastery_50", stats["total_characters_mastered"])
		set_progress("mastery_100", stats["total_characters_mastered"])
		set_progress("mastery_500", stats["total_characters_mastered"])

	if stats.has("current_streak"):
		set_progress("streak_7", stats["current_streak"])
		set_progress("streak_30", stats["current_streak"])
		set_progress("streak_100", stats["current_streak"])

	if stats.has("total_runs"):
		set_progress("runs_10", stats["total_runs"])
		set_progress("runs_100", stats["total_runs"])

	if stats.has("best_combo"):
		set_progress("combo_10", stats["best_combo"])
		set_progress("combo_50", stats["best_combo"])

	return check_all()


func get_completed_count() -> int:
	return _completed.size()


func get_total_count() -> int:
	return _definitions.size()


func get_completion_percentage() -> float:
	if _definitions.is_empty():
		return 0.0
	return float(_completed.size()) / float(_definitions.size())


func to_dict() -> Dictionary:
	return {
		"completed": _completed,
		"progress": _progress,
	}


static func from_dict(data: Dictionary) -> MilestoneTracker:
	var mt := MilestoneTracker.new()
	mt._completed = data.get("completed", {})
	mt._progress = data.get("progress", {})
	return mt
