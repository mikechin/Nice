## SwipeDetector — Handles touch/mouse input for four-directional swiping.
class_name SwipeDetector
extends Control

signal swipe_completed(direction: String)  # "up", "down", "left", "right"
signal swipe_cancelled()

var swipe_start: Vector2 = Vector2.ZERO
var is_swiping: bool = false
var is_enabled: bool = true
var min_swipe_distance: float = 80.0
var max_swipe_time: float = 1.0  # seconds

var _swipe_start_time: float = 0.0


func _gui_input(event: InputEvent) -> void:
	# _gui_input (not _input) so events outside our rect — or consumed by an
	# overlay button — don't accidentally start a swipe.
	if not is_enabled:
		return

	if event is InputEventScreenTouch:
		# Only the primary finger drives the swipe; extra fingers must not reset state.
		if event.index != 0:
			return
		if event.pressed:
			_start_swipe(event.position)
		elif is_swiping:
			_end_swipe(event.position)
			accept_event()
	elif event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			_start_swipe(event.position)
		elif is_swiping:
			_end_swipe(event.position)
			accept_event()


func _start_swipe(pos: Vector2) -> void:
	if is_swiping:
		return  # Already tracking a swipe; ignore re-entry from a stray press.
	swipe_start = pos
	is_swiping = true
	_swipe_start_time = Time.get_ticks_msec() / 1000.0


func _end_swipe(pos: Vector2) -> void:
	if not is_swiping:
		return

	is_swiping = false
	var delta := pos - swipe_start
	var distance := delta.length()
	var elapsed := Time.get_ticks_msec() / 1000.0 - _swipe_start_time

	if distance < min_swipe_distance or elapsed > max_swipe_time:
		swipe_cancelled.emit()
		return

	var direction := _get_swipe_direction(delta)
	swipe_completed.emit(direction)


func _get_swipe_direction(delta: Vector2) -> String:
	var abs_delta := delta.abs()
	if abs_delta.y > abs_delta.x:
		return "up" if delta.y < 0 else "down"
	else:
		return "left" if delta.x < 0 else "right"


func reset() -> void:
	is_swiping = false
	swipe_start = Vector2.ZERO


func set_enabled(enabled: bool) -> void:
	is_enabled = enabled
	if not enabled:
		reset()
