## AccessibilityManager — Manages accessibility settings.
## Font scaling, color blind modes, haptic feedback preferences.
class_name AccessibilityManagerClass
extends Node

signal settings_changed()

enum ColorBlindMode { NONE, PROTANOPIA, DEUTERANOPIA, TRITANOPIA }

var font_scale: float = 1.0
var color_blind_mode: ColorBlindMode = ColorBlindMode.NONE
var haptic_enabled: bool = true
var reduced_motion: bool = false
var high_contrast: bool = false
var screen_reader_hints: bool = false

const MIN_FONT_SCALE: float = 0.75
const MAX_FONT_SCALE: float = 2.0
const FONT_SCALE_STEP: float = 0.25


func set_font_scale(scale: float) -> void:
	font_scale = clampf(scale, MIN_FONT_SCALE, MAX_FONT_SCALE)
	settings_changed.emit()


func increase_font_scale() -> void:
	set_font_scale(font_scale + FONT_SCALE_STEP)


func decrease_font_scale() -> void:
	set_font_scale(font_scale - FONT_SCALE_STEP)


func set_color_blind_mode(mode: ColorBlindMode) -> void:
	color_blind_mode = mode
	settings_changed.emit()


func set_haptic_enabled(enabled: bool) -> void:
	haptic_enabled = enabled
	settings_changed.emit()


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	settings_changed.emit()


func set_high_contrast(enabled: bool) -> void:
	high_contrast = enabled
	settings_changed.emit()


## Adjust a color for the current color blind mode.
func adjust_color(color: Color) -> Color:
	match color_blind_mode:
		ColorBlindMode.PROTANOPIA:
			return _simulate_protanopia(color)
		ColorBlindMode.DEUTERANOPIA:
			return _simulate_deuteranopia(color)
		ColorBlindMode.TRITANOPIA:
			return _simulate_tritanopia(color)
	return color


func _simulate_protanopia(c: Color) -> Color:
	# Simplified protanopia simulation
	return Color(
		0.567 * c.r + 0.433 * c.g,
		0.558 * c.r + 0.442 * c.g,
		0.242 * c.g + 0.758 * c.b,
		c.a
	)


func _simulate_deuteranopia(c: Color) -> Color:
	return Color(
		0.625 * c.r + 0.375 * c.g,
		0.700 * c.r + 0.300 * c.g,
		0.300 * c.g + 0.700 * c.b,
		c.a
	)


func _simulate_tritanopia(c: Color) -> Color:
	return Color(
		0.950 * c.r + 0.050 * c.g,
		0.433 * c.g + 0.567 * c.b,
		0.475 * c.g + 0.525 * c.b,
		c.a
	)


func get_animation_speed_multiplier() -> float:
	return 0.0 if reduced_motion else 1.0


func to_dict() -> Dictionary:
	return {
		"font_scale": font_scale,
		"color_blind_mode": color_blind_mode,
		"haptic_enabled": haptic_enabled,
		"reduced_motion": reduced_motion,
		"high_contrast": high_contrast,
		"screen_reader_hints": screen_reader_hints,
	}


func load_from_dict(data: Dictionary) -> void:
	font_scale = data.get("font_scale", 1.0)
	color_blind_mode = data.get("color_blind_mode", ColorBlindMode.NONE)
	haptic_enabled = data.get("haptic_enabled", true)
	reduced_motion = data.get("reduced_motion", false)
	high_contrast = data.get("high_contrast", false)
	screen_reader_hints = data.get("screen_reader_hints", false)
	settings_changed.emit()
