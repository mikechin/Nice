## SwipeArea — Interactive swipe zone wrapping SwipeDetector.
## Displays directional arrow indicators and answer labels at each edge.
## Emits direction_swiped when the player completes a valid swipe.
class_name SwipeArea
extends Control

signal direction_swiped(direction: String)

@onready var _up_arrow: Label = $UpArrow if has_node("UpArrow") else null
@onready var _down_arrow: Label = $DownArrow if has_node("DownArrow") else null
@onready var _left_arrow: Label = $LeftArrow if has_node("LeftArrow") else null
@onready var _right_arrow: Label = $RightArrow if has_node("RightArrow") else null
@onready var _up_label: Control = $UpLabel if has_node("UpLabel") else null
@onready var _down_label: Control = $DownLabel if has_node("DownLabel") else null
@onready var _left_label: Control = $LeftLabel if has_node("LeftLabel") else null
@onready var _right_label: Control = $RightLabel if has_node("RightLabel") else null

var _swipe_detector: SwipeDetector
var _is_enabled: bool = true
var _answer_map: Dictionary = {}

const ARROW_CHARS: Dictionary = {
	"up": "^",
	"down": "v",
	"left": "<",
	"right": ">",
}

const VECTOR_BY_LABEL: Dictionary = {
	"up": Vector2.UP,
	"down": Vector2.DOWN,
	"left": Vector2.LEFT,
	"right": Vector2.RIGHT,
}

const IDLE_ALPHA: float = 0.4
const ACTIVE_ALPHA: float = 1.0


func _ready() -> void:
	_warn_missing_nodes()
	_swipe_detector = SwipeDetector.new()
	add_child(_swipe_detector)
	_swipe_detector.set_anchors_preset(Control.PRESET_FULL_RECT)
	_swipe_detector.swipe_completed.connect(_on_swipe_completed)
	_swipe_detector.swipe_cancelled.connect(_on_swipe_cancelled)

	_setup_arrows()


func _setup_arrows() -> void:
	var arrows: Dictionary = {
		"up": _up_arrow,
		"down": _down_arrow,
		"left": _left_arrow,
		"right": _right_arrow,
	}
	for dir_key in arrows:
		var arrow: Label = arrows[dir_key]
		if arrow:
			arrow.text = ARROW_CHARS[dir_key]
			arrow.modulate.a = IDLE_ALPHA


func set_answers(answers: Dictionary) -> void:
	_answer_map = answers
	_update_answer_labels()


func set_enabled(enabled: bool) -> void:
	_is_enabled = enabled
	_swipe_detector.set_enabled(enabled)
	modulate.a = ACTIVE_ALPHA if enabled else IDLE_ALPHA * 0.5


func is_enabled() -> bool:
	return _is_enabled


func get_swipe_detector() -> SwipeDetector:
	return _swipe_detector


func _update_answer_labels() -> void:
	var label_map: Dictionary = {
		"up": _up_label,
		"down": _down_label,
		"left": _left_label,
		"right": _right_label,
	}
	for dir_key in label_map:
		var label: Control = label_map[dir_key]
		if label == null:
			continue
		var text: String = _answer_map.get(dir_key, "")
		if label.has_method("set_answer"):
			var is_correct: bool = dir_key == _answer_map.get("correct_direction", "")
			label.set_answer(text, is_correct)
		elif label is Label:
			label.text = text


func clear_answers() -> void:
	_answer_map.clear()
	var labels: Array[Control] = [_up_label, _down_label, _left_label, _right_label]
	for label in labels:
		if label == null:
			continue
		if label.has_method("clear_answer"):
			label.clear_answer()
		elif label is Label:
			label.text = ""


func _on_swipe_completed(direction: String) -> void:
	if not _is_enabled:
		return
	_flash_direction(direction)
	direction_swiped.emit(direction)
	SignalBus.swipe_detected.emit(VECTOR_BY_LABEL.get(direction, Vector2.ZERO))

	var answer: String = _answer_map.get(direction, "")
	if answer != "":
		SignalBus.answer_selected.emit(direction, answer)


func _on_swipe_cancelled() -> void:
	_reset_arrow_colors()


func _flash_direction(direction: String) -> void:
	var arrows: Dictionary = {
		"up": _up_arrow,
		"down": _down_arrow,
		"left": _left_arrow,
		"right": _right_arrow,
	}
	var arrow: Label = arrows.get(direction)
	if arrow == null:
		return

	var tween := create_tween()
	arrow.modulate.a = ACTIVE_ALPHA
	tween.tween_property(arrow, "modulate:a", IDLE_ALPHA, 0.4)


func _reset_arrow_colors() -> void:
	var arrows: Array[Label] = [_up_arrow, _down_arrow, _left_arrow, _right_arrow]
	for arrow in arrows:
		if arrow:
			arrow.modulate.a = IDLE_ALPHA


func _warn_missing_nodes() -> void:
	if _up_arrow == null:
		push_warning("swipe_area.gd: missing node _up_arrow")
	if _down_arrow == null:
		push_warning("swipe_area.gd: missing node _down_arrow")
	if _left_arrow == null:
		push_warning("swipe_area.gd: missing node _left_arrow")
	if _right_arrow == null:
		push_warning("swipe_area.gd: missing node _right_arrow")
	if _up_label == null:
		push_warning("swipe_area.gd: missing node _up_label")
	if _down_label == null:
		push_warning("swipe_area.gd: missing node _down_label")
	if _left_label == null:
		push_warning("swipe_area.gd: missing node _left_label")
	if _right_label == null:
		push_warning("swipe_area.gd: missing node _right_label")
