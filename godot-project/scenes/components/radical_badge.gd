## RadicalBadge — Small badge showing a radical with rarity-colored background.
## Used in radical equip panels, shop cards, and card detail views.
class_name RadicalBadge
extends Control

signal badge_tapped(radical: String)

@onready var _radical_label: Label = $RadicalLabel if has_node("RadicalLabel") else null
@onready var _name_label: Label = $NameLabel if has_node("NameLabel") else null
@onready var _background: Panel = $Background if has_node("Background") else null
@onready var _equipped_indicator: Control = $EquippedIndicator if has_node("EquippedIndicator") else null

var _radical: String = ""
var _rarity_tier: String = "common"
var _is_equipped: bool = false
var _radical_data: RadicalData

const RARITY_COLORS: Dictionary = {
	"common": Color(0.6, 0.6, 0.6),
	"uncommon": Color(0.2, 0.8, 0.2),
	"rare": Color(0.2, 0.4, 1.0),
	"epic": Color(0.7, 0.2, 1.0),
	"legendary": Color(1.0, 0.8, 0.0),
}

const BADGE_SIZE := Vector2(56, 56)


func _ready() -> void:
	_warn_missing_nodes()
	custom_minimum_size = BADGE_SIZE
	gui_input.connect(_on_gui_input)


func setup_badge(radical_data: RadicalData, is_equipped: bool = false) -> void:
	_radical_data = radical_data
	_radical = radical_data.radical
	_rarity_tier = radical_data.rarity_tier
	_is_equipped = is_equipped
	_update_display()


func setup_from_string(radical: String, rarity_tier: String = "common", is_equipped: bool = false) -> void:
	_radical = radical
	_rarity_tier = rarity_tier
	_is_equipped = is_equipped
	_update_display()


func set_equipped(is_equipped: bool) -> void:
	_is_equipped = is_equipped
	if _equipped_indicator:
		_equipped_indicator.visible = _is_equipped


func get_radical() -> String:
	return _radical


func is_equipped() -> bool:
	return _is_equipped


func _update_display() -> void:
	var color: Color = RARITY_COLORS.get(_rarity_tier, Color(0.6, 0.6, 0.6))

	if _radical_label:
		_radical_label.text = _radical
		_radical_label.add_theme_color_override("font_color", Color.WHITE)

	if _name_label:
		if _radical_data:
			_name_label.text = _radical_data.display_name
		else:
			_name_label.text = _radical

	if _background:
		_background.modulate = color

	if _equipped_indicator:
		_equipped_indicator.visible = _is_equipped


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		badge_tapped.emit(_radical)
		_animate_tap()


func _animate_tap() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)


func _warn_missing_nodes() -> void:
	if _radical_label == null:
		push_warning("radical_badge.gd: missing node _radical_label")
	if _name_label == null:
		push_warning("radical_badge.gd: missing node _name_label")
	if _background == null:
		push_warning("radical_badge.gd: missing node _background")
	if _equipped_indicator == null:
		push_warning("radical_badge.gd: missing node _equipped_indicator")
