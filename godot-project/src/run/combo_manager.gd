## ComboManager — Tracks combo streaks and milestones.
class_name ComboManager
extends RefCounted

var current_combo: int = 0
var best_combo: int = 0
var milestones: Array[int] = [5, 10, 20, 50, 100]
var _last_milestone_hit: int = 0


func reset() -> void:
	current_combo = 0
	_last_milestone_hit = 0


func increment() -> void:
	current_combo += 1
	best_combo = maxi(best_combo, current_combo)
	SignalBus.combo_incremented.emit(current_combo)

	for milestone in milestones:
		if current_combo == milestone:
			_last_milestone_hit = milestone
			SignalBus.combo_milestone.emit(milestone)
			break


func break_combo() -> void:
	if current_combo > 0:
		SignalBus.combo_broken.emit(current_combo)
	current_combo = 0
	_last_milestone_hit = 0


## Combo multiplier: starts at 1.0, increases with streak.
func get_multiplier() -> float:
	if current_combo < 5:
		return 1.0
	elif current_combo < 10:
		return 1.25
	elif current_combo < 20:
		return 1.5
	elif current_combo < 50:
		return 2.0
	else:
		return 3.0


func is_milestone(count: int) -> bool:
	return count in milestones


func get_next_milestone() -> int:
	for m in milestones:
		if current_combo < m:
			return m
	return -1  # All milestones passed


func get_progress_to_next_milestone() -> float:
	var next := get_next_milestone()
	if next < 0:
		return 1.0
	var prev := 0
	for m in milestones:
		if m >= next:
			break
		prev = m
	var range_size := next - prev
	if range_size <= 0:
		return 1.0
	return float(current_combo - prev) / float(range_size)
