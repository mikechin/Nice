## AnswerLabel — Label positioned at one of four directions showing an answer option.
## Handles reveal animation and correct/incorrect coloring after the swipe.
class_name AnswerLabel
extends Control

@onready var _text_label: Label = $TextLabel if has_node("TextLabel") else null
@onready var _background: Panel = $Background if has_node("Background") else null

var _direction: String = ""
var _answer_text: String = ""
var _is_correct: bool = false
var _is_revealed: bool = false
var _tween: Tween

const CORRECT_COLOR := Color(0.2, 0.9, 0.2)
const INCORRECT_COLOR := Color(0.9, 0.2, 0.2)
const NEUTRAL_COLOR := Color(0.9, 0.9, 0.9)
const DIMMED_COLOR := Color(0.5, 0.5, 0.5)


func _ready() -> void:
	_warn_missing_nodes()
	_update_display()


func set_direction(direction: String) -> void:
	_direction = direction


func get_direction() -> String:
	return _direction


func set_answer(text: String, is_correct: bool = false) -> void:
	_answer_text = text
	_is_correct = is_correct
	_is_revealed = false
	_update_display()
	_animate_in()


func clear_answer() -> void:
	_answer_text = ""
	_is_correct = false
	_is_revealed = false
	_update_display()


func reveal_correct(was_selected: bool) -> void:
	_is_revealed = true
	if was_selected and _is_correct:
		_show_as_correct()
	elif was_selected and not _is_correct:
		_show_as_incorrect()
	elif _is_correct:
		_show_as_correct()
	else:
		_dim()


func get_answer_text() -> String:
	return _answer_text


func is_correct() -> bool:
	return _is_correct


func _update_display() -> void:
	if _text_label:
		_text_label.text = _answer_text
		if not _is_revealed:
			_text_label.add_theme_color_override("font_color", NEUTRAL_COLOR)

	if _background:
		_background.modulate = Color(1, 1, 1, 0.1)

	visible = _answer_text != ""


func _animate_in() -> void:
	_kill_tween()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)


func _show_as_correct() -> void:
	_kill_tween()
	if _text_label:
		_text_label.add_theme_color_override("font_color", CORRECT_COLOR)
	if _background:
		_background.modulate = Color(0.2, 0.9, 0.2, 0.2)
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.1)


func _show_as_incorrect() -> void:
	_kill_tween()
	if _text_label:
		_text_label.add_theme_color_override("font_color", INCORRECT_COLOR)
	if _background:
		_background.modulate = Color(0.9, 0.2, 0.2, 0.2)
	_tween = create_tween()
	var orig_pos := position
	_tween.tween_property(self, "position", orig_pos + Vector2(5, 0), 0.04)
	_tween.tween_property(self, "position", orig_pos - Vector2(5, 0), 0.04)
	_tween.tween_property(self, "position", orig_pos, 0.04)


func _dim() -> void:
	_kill_tween()
	_tween = create_tween()
	if _text_label:
		_text_label.add_theme_color_override("font_color", DIMMED_COLOR)
	_tween.tween_property(self, "modulate:a", 0.4, 0.3)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _warn_missing_nodes() -> void:
	if _text_label == null:
		push_warning("answer_label.gd: missing node _text_label")
	if _background == null:
		push_warning("answer_label.gd: missing node _background")
