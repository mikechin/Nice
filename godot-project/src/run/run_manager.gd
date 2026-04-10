## RunManager — Controls the flow of a complete run session.
## Manages rounds, difficulty scaling, and session tracking.
class_name RunManager
extends RefCounted

signal run_completed(summary: Dictionary)
signal round_ready(card_ids: Array)
var run_type: String = ""
var round_count: int = 0
var max_rounds: int = 5
var is_active: bool = false

var _difficulty: DifficultyManager
var _round: RoundManager
var _session: SessionData
var _pack: PackData


func _init() -> void:
	_difficulty = DifficultyManager.new()
	_round = RoundManager.new()


func start_run(type: String, pack: PackData) -> void:
	run_type = type
	_pack = pack
	round_count = 0
	is_active = true

	_difficulty.reset()

	_session = SessionData.new()
	_session.session_id = str(roundi(Time.get_unix_time_from_system()))
	_session.started_at = Time.get_unix_time_from_system()
	_session.run_type = type

	start_next_round()


func end_run() -> void:
	is_active = false
	_session.ended_at = Time.get_unix_time_from_system()

	var summary := get_run_summary()
	run_completed.emit(summary)


func start_next_round() -> void:
	round_count += 1
	_difficulty.on_round_changed(round_count)

	var cards_needed := _difficulty.get_cards_for_round(round_count)
	var card_ids := _get_cards_for_round(cards_needed)
	_round.start_round(card_ids, round_count)
	round_ready.emit(card_ids)


func on_card_answered(card_id: String, challenge_type: String, correct: bool, rating: int) -> void:
	if not is_active:
		return

	var time_ms := 0  # Could track per-card timing
	_session.record_answer(card_id, challenge_type, correct, rating, time_ms)

	_round.on_card_answered(correct)

	# Check round complete
	if _round.is_round_complete():
		on_round_completed()


func on_round_completed() -> void:
	if round_count >= max_rounds:
		end_run()
	else:
		start_next_round()


func _get_cards_for_round(count: int) -> Array[String]:
	if _pack == null or _pack.presentation_order.is_empty():
		return []
	# Pull next batch from presentation order
	var start_idx := (round_count - 1) * count
	var result: Array[String] = []
	for i in count:
		var idx := (start_idx + i) % _pack.presentation_order.size()
		result.append(_pack.presentation_order[idx])
	return result


func get_run_summary() -> Dictionary:
	return {
		"run_type": run_type,
		"rounds_completed": round_count,
		"total_cards": _session.total_cards,
		"correct_count": _session.correct_count,
		"accuracy": _session.get_accuracy(),
		"duration_seconds": _session.get_duration_seconds(),
		"new_cards_seen": _session.new_cards_seen,
	}


func get_difficulty_manager() -> DifficultyManager:
	return _difficulty


func get_round_manager() -> RoundManager:
	return _round


func get_session_data() -> SessionData:
	return _session
