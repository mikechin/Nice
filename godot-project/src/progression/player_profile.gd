## PlayerProfile — Tracks long-term player progression and HSK level.
class_name PlayerProfile
extends RefCounted

var hsk_level: int = 2
var mastery_percentages: Dictionary = {}  # hsk_level -> float (0.0 to 1.0)
var total_characters_mastered: int = 0
var total_runs_completed: int = 0
var total_play_time_seconds: float = 0.0
var total_cards_reviewed: int = 0
var total_correct_answers: int = 0

const LEVEL_UP_THRESHOLD: float = 0.85  # 85% mastery to advance
const MAX_HSK_LEVEL: int = 5


func update_mastery(level: int, mastered_count: int, total_count: int) -> void:
	if total_count > 0:
		mastery_percentages[level] = float(mastered_count) / float(total_count)
	else:
		mastery_percentages[level] = 0.0


func check_level_up() -> bool:
	var current_mastery := get_mastery_for_level(hsk_level)
	if current_mastery >= LEVEL_UP_THRESHOLD and hsk_level < MAX_HSK_LEVEL:
		hsk_level += 1
		return true
	return false


func get_mastery_for_level(level: int) -> float:
	return mastery_percentages.get(level, 0.0)


func get_overall_mastery() -> float:
	if mastery_percentages.is_empty():
		return 0.0
	var total := 0.0
	for level in mastery_percentages:
		total += mastery_percentages[level]
	return total / float(mastery_percentages.size())


func record_run(session: SessionData) -> void:
	total_runs_completed += 1
	total_play_time_seconds += session.get_duration_seconds()
	total_cards_reviewed += session.total_cards
	total_correct_answers += session.correct_count


func get_accuracy() -> float:
	if total_cards_reviewed == 0:
		return 0.0
	return float(total_correct_answers) / float(total_cards_reviewed)


func to_dict() -> Dictionary:
	return {
		"hsk_level": hsk_level,
		"mastery_percentages": mastery_percentages,
		"total_characters_mastered": total_characters_mastered,
		"total_runs_completed": total_runs_completed,
		"total_play_time_seconds": total_play_time_seconds,
		"total_cards_reviewed": total_cards_reviewed,
		"total_correct_answers": total_correct_answers,
	}


static func from_dict(data: Dictionary) -> PlayerProfile:
	var pp := PlayerProfile.new()
	pp.hsk_level = data.get("hsk_level", 2)
	pp.mastery_percentages = data.get("mastery_percentages", {})
	pp.total_characters_mastered = data.get("total_characters_mastered", 0)
	pp.total_runs_completed = data.get("total_runs_completed", 0)
	pp.total_play_time_seconds = data.get("total_play_time_seconds", 0.0)
	pp.total_cards_reviewed = data.get("total_cards_reviewed", 0)
	pp.total_correct_answers = data.get("total_correct_answers", 0)
	return pp
