## SentenceSlot — Single slot in the sentence builder showing a placed tile.
## Tappable to remove the tile from the sentence. Shows position index.
class_name SentenceSlot
extends Control

signal slot_tapped(position: int)

@onready var _character_label: Label = $CharacterLabel if has_node("CharacterLabel") else null
@onready var _background: Panel = $Background if has_node("Background") else null
@onready var _index_label: Label = $IndexLabel if has_node("IndexLabel") else null

var _character: String = ""
var _slot_position: int = -1
var _is_empty: bool = true

const SLOT_SIZE := Vector2(52, 52)
const FILLED_COLOR := Color(0.2, 0.5, 0.9, 0.3)
const EMPTY_COLOR := Color(0.3, 0.3, 0.3, 0.15)


func _ready() -> void:
	custom_minimum_size = SLOT_SIZE
	gui_input.connect(_on_gui_input)
	_update_display()


func setup_slot(character: String, position: int) -> void:
	_character = character
	_slot_position = position
	_is_empty = character.is_empty()
	_update_display()
	_animate_place()


func clear_slot() -> void:
	_character = ""
	_is_empty = true
	_update_display()


func get_character() -> String:
	return _character


func get_slot_position() -> int:
	return _slot_position


func is_empty() -> bool:
	return _is_empty


func _update_display() -> void:
	if _character_label:
		_character_label.text = _character if not _is_empty else ""

	if _background:
		_background.modulate = FILLED_COLOR if not _is_empty else EMPTY_COLOR

	if _index_label:
		if _slot_position >= 0 and not _is_empty:
			_index_label.text = str(_slot_position + 1)
		else:
			_index_label.text = ""


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not _is_empty:
		slot_tapped.emit(_slot_position)
		_animate_remove()


func _animate_place() -> void:
	if _is_empty:
		return
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)


func _animate_remove() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.08)
	tween.tween_property(self, "modulate:a", 0.3, 0.1)
