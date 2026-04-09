## DifficultyManager — Scales card pacing and difficulty within a run.
## Controls speed increase during combos and round escalation.
class_name DifficultyManager
extends RefCounted

var base_card_interval: float = 3.0  # seconds between cards
var current_interval: float = 3.0
var min_interval: float = 1.0
var _current_round: int = 0

const COMBO_SPEED_FACTOR: float = 0.05   # 5% faster per 10 combo
const ROUND_SPEED_FACTOR: float = 0.1    # 10% faster per round
const BASE_CARDS_PER_ROUND: int = 8
const CARDS_PER_ROUND_INCREASE: int = 2


func reset() -> void:
	current_interval = base_card_interval
	_current_round = 0


func on_combo_changed(combo: int) -> void:
	var combo_reduction := COMBO_SPEED_FACTOR * floorf(float(combo) / 10.0)
	var round_reduction := ROUND_SPEED_FACTOR * float(_current_round)
	current_interval = maxf(
		min_interval,
		base_card_interval * (1.0 - combo_reduction - round_reduction)
	)


func on_round_changed(round_number: int) -> void:
	_current_round = round_number
	# Recalculate with current combo = 0 at round start
	on_combo_changed(0)


func get_current_interval() -> float:
	return current_interval


func get_cards_for_round(round_number: int) -> int:
	return BASE_CARDS_PER_ROUND + CARDS_PER_ROUND_INCREASE * round_number


func get_challenge_type_weights(round_number: int) -> Dictionary:
	# Later rounds introduce harder challenge types
	if round_number <= 1:
		return {"meaning": 0.6, "character": 0.4, "pinyin": 0.0, "tone": 0.0}
	elif round_number <= 3:
		return {"meaning": 0.4, "character": 0.3, "pinyin": 0.2, "tone": 0.1}
	else:
		return {"meaning": 0.25, "character": 0.25, "pinyin": 0.25, "tone": 0.25}
