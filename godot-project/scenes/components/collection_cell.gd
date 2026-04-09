## CollectionCell — Single grid cell in the collection view.
## Shows the character with background colored by tier. Locked characters appear dimmed.
class_name CollectionCell
extends Control

signal cell_tapped(character: String)

@onready var _character_label: Label = $CharacterLabel if has_node("CharacterLabel") else null
@onready var _tier_label: Label = $TierLabel if has_node("TierLabel") else null
@onready var _background: Panel = $Background if has_node("Background") else null
@onready var _border: Panel = $Border if has_node("Border") else null
@onready var _lock_icon: Label = $LockIcon if has_node("LockIcon") else null

var _character: String = ""
var _tier: CollectionEnums.CardTier = CollectionEnums.CardTier.LOCKED
var _card_data: CharacterData

const CELL_SIZE := Vector2(72, 72)


func _ready() -> void:
	custom_minimum_size = CELL_SIZE
	gui_input.connect(_on_gui_input)


func setup_cell(character: String, tier: CollectionEnums.CardTier, card_data: CharacterData = null) -> void:
	_character = character
	_tier = tier
	_card_data = card_data
	_update_display()


func get_character() -> String:
	return _character


func get_tier() -> CollectionEnums.CardTier:
	return _tier


func _update_display() -> void:
	var is_locked: bool = _tier == CollectionEnums.CardTier.LOCKED
	var tier_color: Color = CollectionEnums.tier_color(_tier)

	# Character label
	if _character_label:
		if is_locked:
			_character_label.text = "?"
			_character_label.modulate.a = 0.4
		else:
			_character_label.text = _character
			_character_label.modulate.a = 1.0

	# Tier name
	if _tier_label:
		if is_locked:
			_tier_label.text = ""
		else:
			_tier_label.text = CollectionEnums.tier_name(_tier)
			_tier_label.add_theme_color_override("font_color", tier_color)

	# Background color tint
	if _background:
		var bg_color := tier_color
		bg_color.a = 0.15 if not is_locked else 0.05
		_background.modulate = bg_color

	# Border color
	if _border:
		_border.modulate = tier_color

	# Lock icon
	if _lock_icon:
		_lock_icon.visible = is_locked
		_lock_icon.text = "L"


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		cell_tapped.emit(_character)
		_animate_tap()


func _animate_tap() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
