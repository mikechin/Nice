## CharSlot — Character display for the sentence builder.
## Shows a character with count badge. Tappable for placement.
class_name CharSlot
extends Control

signal char_tapped(character: String)

@onready var _character_label: Label = $CharacterLabel if has_node("CharacterLabel") else null
@onready var _count_label: Label = $CountLabel if has_node("CountLabel") else null
@onready var _background: Panel = $Background if has_node("Background") else null

var _character: String = ""
var _count: int = 0
var _is_selected: bool = false

const SLOT_SIZE := Vector2(56, 56)
const DEFAULT_COLOR := Color(0.25, 0.35, 0.55, 0.8)
const SELECTED_COLOR := Color(0.4, 0.6, 0.9, 0.9)
const DEPLETED_COLOR := Color(0.3, 0.3, 0.3, 0.3)


func _ready() -> void:
	_warn_missing_nodes()
	custom_minimum_size = SLOT_SIZE
	gui_input.connect(_on_gui_input)
	_update_display()


func setup(character: String, count: int = 1) -> void:
	_character = character
	_count = count
	_is_selected = false
	_update_display()


func set_count(count: int) -> void:
	_count = count
	_update_display()


func set_selected(selected: bool) -> void:
	_is_selected = selected
	_update_display()


func get_character() -> String:
	return _character


func get_count() -> int:
	return _count


func is_depleted() -> bool:
	return _count <= 0


func _update_display() -> void:
	if _character_label:
		_character_label.text = _character
		_character_label.modulate.a = 1.0 if _count > 0 else 0.3

	if _count_label:
		if _count > 1:
			_count_label.visible = true
			_count_label.text = "x%d" % _count
		else:
			_count_label.visible = false

	if _background:
		if _count <= 0:
			_background.modulate = DEPLETED_COLOR
		elif _is_selected:
			_background.modulate = SELECTED_COLOR
		else:
			_background.modulate = DEFAULT_COLOR


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and _count > 0:
		char_tapped.emit(_character)
		_animate_tap()


func _animate_tap() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _warn_missing_nodes() -> void:
	if _character_label == null:
		push_warning("char_slot.gd: missing node _character_label")
	if _count_label == null:
		push_warning("char_slot.gd: missing node _count_label")
	if _background == null:
		push_warning("char_slot.gd: missing node _background")
