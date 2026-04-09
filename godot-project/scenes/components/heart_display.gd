## HeartDisplay — Shows heart icons representing remaining lives.
## Updates on hearts_changed signal with loss animation.
class_name HeartDisplay
extends Control

@onready var _hearts_container: HBoxContainer = $HeartsContainer if has_node("HeartsContainer") else null
@onready var _count_label: Label = $CountLabel if has_node("CountLabel") else null

var _current_hearts: int = 0
var _max_hearts: int = 3
var _heart_nodes: Array[Control] = []
var _tween: Tween

const HEART_FULL_COLOR := Color(1.0, 0.2, 0.3)
const HEART_EMPTY_COLOR := Color(0.3, 0.3, 0.3, 0.4)
const HEART_SIZE := Vector2(32, 32)


func _ready() -> void:
	SignalBus.hearts_changed.connect(_on_hearts_changed)
	SignalBus.heart_lost.connect(_on_heart_lost)


func set_hearts(current: int, max_hearts: int) -> void:
	_current_hearts = current
	_max_hearts = max_hearts
	_rebuild_hearts()


func get_current_hearts() -> int:
	return _current_hearts


func get_max_hearts() -> int:
	return _max_hearts


func _rebuild_hearts() -> void:
	_heart_nodes.clear()

	if _hearts_container:
		for child in _hearts_container.get_children():
			child.queue_free()

		for i in _max_hearts:
			var heart := _create_heart_icon(i < _current_hearts)
			_hearts_container.add_child(heart)
			_heart_nodes.append(heart)

	if _count_label:
		_count_label.text = "%d / %d" % [_current_hearts, _max_hearts]


func _create_heart_icon(is_full: bool) -> Control:
	var heart := ColorRect.new()
	heart.custom_minimum_size = HEART_SIZE
	heart.size = HEART_SIZE
	heart.color = HEART_FULL_COLOR if is_full else HEART_EMPTY_COLOR

	# Use a label with a heart character as a simple heart icon
	var label := Label.new()
	label.text = "♥" if is_full else "♡"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	heart.color = Color.TRANSPARENT
	if is_full:
		label.add_theme_color_override("font_color", HEART_FULL_COLOR)
	else:
		label.add_theme_color_override("font_color", HEART_EMPTY_COLOR)
	heart.add_child(label)

	return heart


func _on_hearts_changed(current: int, max_hearts: int) -> void:
	var old_hearts := _current_hearts
	_current_hearts = current
	_max_hearts = max_hearts

	if _heart_nodes.size() != _max_hearts:
		_rebuild_hearts()
		return

	# Update individual heart colors
	for i in _heart_nodes.size():
		var heart: Control = _heart_nodes[i]
		var label: Label = heart.get_child(0) if heart.get_child_count() > 0 else null
		if label:
			if i < current:
				label.text = "♥"
				label.add_theme_color_override("font_color", HEART_FULL_COLOR)
			else:
				label.text = "♡"
				label.add_theme_color_override("font_color", HEART_EMPTY_COLOR)

	if _count_label:
		_count_label.text = "%d / %d" % [current, max_hearts]


func _on_heart_lost() -> void:
	# Animate the lost heart
	var lost_idx := _current_hearts  # The heart at this index just emptied
	if lost_idx >= 0 and lost_idx < _heart_nodes.size():
		_animate_heart_loss(_heart_nodes[lost_idx])


func _animate_heart_loss(heart_node: Control) -> void:
	_kill_tween()
	_tween = create_tween()

	# Shake and fade
	var orig_pos := heart_node.position
	_tween.tween_property(heart_node, "position", orig_pos + Vector2(4, 0), 0.05)
	_tween.tween_property(heart_node, "position", orig_pos - Vector2(4, 0), 0.05)
	_tween.tween_property(heart_node, "position", orig_pos, 0.05)
	_tween.tween_property(heart_node, "modulate:a", 0.3, 0.1)
	_tween.tween_property(heart_node, "modulate:a", 1.0, 0.1)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
