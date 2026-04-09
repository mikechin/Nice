## HeartsManager — Tracks hearts (lives) during a run.
class_name HeartsManager
extends RefCounted

var current_hearts: int = 3
var max_hearts: int = 3


func reset(max_h: int = 3) -> void:
	max_hearts = max_h
	current_hearts = max_h
	SignalBus.hearts_changed.emit(current_hearts, max_hearts)


func lose_heart() -> void:
	current_hearts = maxi(0, current_hearts - 1)
	SignalBus.heart_lost.emit()
	SignalBus.hearts_changed.emit(current_hearts, max_hearts)
	if current_hearts <= 0:
		SignalBus.all_hearts_lost.emit()


func add_heart(count: int = 1) -> void:
	current_hearts = mini(current_hearts + count, max_hearts)
	SignalBus.hearts_changed.emit(current_hearts, max_hearts)


func is_game_over() -> bool:
	return current_hearts <= 0


func get_hearts() -> int:
	return current_hearts


func get_hearts_percentage() -> float:
	if max_hearts <= 0:
		return 0.0
	return float(current_hearts) / float(max_hearts)
