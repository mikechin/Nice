## WeeklyTrialManager — Tracks weekly trial progress and goals.
class_name WeeklyTrialManager
extends RefCounted

var current_trial: Dictionary = {}
var trial_progress: Dictionary = {}  # trial_id -> { sentences_completed, score }
var _sentence_db: SentenceDatabase

const TRIAL_SENTENCES_REQUIRED: int = 3
const TRIAL_REWARD_COINS: int = 200


func _init(sentence_db: SentenceDatabase = null) -> void:
	_sentence_db = sentence_db


func load_current_trial(hsk_level: int) -> Dictionary:
	if _sentence_db == null:
		return {}
	var week := _get_week_string()
	current_trial = _sentence_db.get_weekly_trial(hsk_level, week)
	if not current_trial.is_empty():
		var trial_id: String = current_trial.get("id", week)
		if trial_id not in trial_progress:
			trial_progress[trial_id] = {"sentences_completed": 0, "score": 0}
	return current_trial


func submit_trial_sentence(sentence: String, chars_used: Array) -> Dictionary:
	var trial_id: String = current_trial.get("id", _get_week_string())
	if trial_id not in trial_progress:
		trial_progress[trial_id] = {"sentences_completed": 0, "score": 0}

	var progress: Dictionary = trial_progress[trial_id]
	var score := chars_used.size() * 20 + 75
	progress["sentences_completed"] += 1
	progress["score"] += score

	if is_trial_complete():
		SignalBus.weekly_trial_completed.emit(trial_id, progress["score"])

	return {
		"sentence_score": score,
		"total_score": progress["score"],
		"sentences_completed": progress["sentences_completed"],
		"trial_complete": is_trial_complete(),
	}


func is_trial_complete() -> bool:
	var trial_id: String = current_trial.get("id", _get_week_string())
	var progress: Dictionary = trial_progress.get(trial_id, {})
	return progress.get("sentences_completed", 0) >= TRIAL_SENTENCES_REQUIRED


func get_trial_requirements() -> Dictionary:
	var trial_id: String = current_trial.get("id", _get_week_string())
	var progress: Dictionary = trial_progress.get(trial_id, {})
	return {
		"sentences_required": TRIAL_SENTENCES_REQUIRED,
		"sentences_completed": progress.get("sentences_completed", 0),
		"reward_coins": TRIAL_REWARD_COINS,
	}


func get_days_remaining() -> int:
	var dt := Time.get_datetime_dict_from_system()
	# Days until Sunday (weekday 0 = Sunday in Godot)
	var weekday: int = dt.get("weekday", 0)
	return (7 - weekday) % 7


func _get_week_string() -> String:
	var dt := Time.get_datetime_dict_from_system()
	var day_of_year: int = dt.get("day", 1)
	var week_number := (day_of_year / 7) + 1
	return "%04d-W%02d" % [dt["year"], week_number]


func to_dict() -> Dictionary:
	return {"trial_progress": trial_progress}


static func from_dict(data: Dictionary, sentence_db: SentenceDatabase = null) -> WeeklyTrialManager:
	var wm := WeeklyTrialManager.new(sentence_db)
	wm.trial_progress = data.get("trial_progress", {})
	return wm
