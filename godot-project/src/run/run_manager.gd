## RunManager — Controls the flow of a complete run session.
## Manages rounds, transitions between swipe phase and boss phase.
class_name RunManager
extends RefCounted

signal run_completed(summary: Dictionary)
signal round_ready(card_ids: Array)
signal boss_round_triggered()

var run_type: String = ""
var round_count: int = 0
var max_rounds: int = 5
var is_active: bool = false

var _combo: ComboManager
var _hearts: HeartsManager
var _difficulty: DifficultyManager
var _round: RoundManager
var _session: SessionData
var _pack: PackData


func _init() -> void:
	_combo = ComboManager.new()
	_hearts = HeartsManager.new()
	_difficulty = DifficultyManager.new()
	_round = RoundManager.new()


func start_run(type: String, pack: PackData) -> void:
	run_type = type
	_pack = pack
	round_count = 0
	is_active = true

	_combo.reset()
	_difficulty.reset()

	match type:
		"easy":
			_hearts.reset(SrsConfig.HEARTS_EASY_RUN)
		"challenge":
			_hearts.reset(SrsConfig.HEARTS_CHALLENGE_RUN)
		_:
			_hearts.reset(SrsConfig.DEFAULT_MAX_HEARTS)

	_session = SessionData.new()
	_session.session_id = str(roundi(Time.get_unix_time_from_system()))
	_session.started_at = Time.get_unix_time_from_system()
	_session.run_type = type

	SignalBus.hearts_changed.emit(_hearts.current_hearts, _hearts.max_hearts)
	start_next_round()


func end_run() -> void:
	is_active = false
	_session.ended_at = Time.get_unix_time_from_system()
	_session.best_combo = _combo.best_combo
	_session.hearts_remaining = _hearts.current_hearts

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

	if correct:
		_combo.increment()
		_difficulty.on_combo_changed(_combo.current_combo)
		SignalBus.combo_incremented.emit(_combo.current_combo)
		for milestone in SrsConfig.COMBO_MILESTONES:
			if _combo.current_combo == milestone:
				SignalBus.combo_milestone.emit(milestone)
				break
	else:
		var old_combo := _combo.current_combo
		_combo.break_combo()
		_difficulty.on_combo_changed(0)
		if old_combo > 0:
			SignalBus.combo_broken.emit(old_combo)
		if run_type == "challenge":
			_hearts.lose_heart()
			SignalBus.heart_lost.emit()
			SignalBus.hearts_changed.emit(_hearts.current_hearts, _hearts.max_hearts)
			if _hearts.is_game_over():
				SignalBus.all_hearts_lost.emit()

	_round.on_card_answered(correct)

	# Check game over
	if _hearts.is_game_over():
		end_run()
		return

	# Check round complete
	if _round.is_round_complete():
		on_round_completed()


func on_round_completed() -> void:
	if round_count >= max_rounds:
		end_run()
	elif _should_trigger_boss():
		boss_round_triggered.emit()
	else:
		start_next_round()


func _should_trigger_boss() -> bool:
	# Boss round every 3 rounds in challenge mode
	return run_type == "challenge" and round_count % 3 == 0


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
		"best_combo": _combo.best_combo,
		"coins_earned": _session.coins_earned,
		"tiles_earned": _session.tiles_earned,
		"hearts_remaining": _hearts.current_hearts,
		"duration_seconds": _session.get_duration_seconds(),
		"new_cards_seen": _session.new_cards_seen,
	}


func get_combo_manager() -> ComboManager:
	return _combo


func get_hearts_manager() -> HeartsManager:
	return _hearts


func get_difficulty_manager() -> DifficultyManager:
	return _difficulty


func get_round_manager() -> RoundManager:
	return _round


func get_session_data() -> SessionData:
	return _session
