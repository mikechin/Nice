## RoundManager — Manages a single round within a run.
## Feeds cards to the swipe mechanic and tracks round progress.
class_name RoundManager
extends RefCounted

var cards_in_round: Array[String] = []  # card IDs
var current_card_index: int = 0
var round_number: int = 0
var _round_correct: int = 0
var _round_total: int = 0
var _round_start_time: float = 0.0


func start_round(card_ids: Array[String], round_num: int) -> void:
	cards_in_round = card_ids
	current_card_index = 0
	round_number = round_num
	_round_correct = 0
	_round_total = 0
	_round_start_time = Time.get_ticks_msec()
	SignalBus.round_started.emit(round_number)


func get_current_card_id() -> String:
	if current_card_index >= cards_in_round.size():
		return ""
	return cards_in_round[current_card_index]


func advance() -> void:
	current_card_index += 1


func on_card_answered(correct: bool) -> void:
	_round_total += 1
	if correct:
		_round_correct += 1
	advance()

	if is_round_complete():
		SignalBus.round_ended.emit(round_number)


func is_round_complete() -> bool:
	return current_card_index >= cards_in_round.size()


func get_round_progress() -> float:
	if cards_in_round.is_empty():
		return 1.0
	return float(current_card_index) / float(cards_in_round.size())


func get_remaining_cards() -> int:
	return maxi(0, cards_in_round.size() - current_card_index)


func get_round_stats() -> Dictionary:
	var elapsed_ms := roundi(Time.get_ticks_msec() - _round_start_time)
	return {
		"round_number": round_number,
		"total_cards": _round_total,
		"correct": _round_correct,
		"accuracy": float(_round_correct) / maxf(1.0, float(_round_total)),
		"elapsed_ms": elapsed_ms,
	}
