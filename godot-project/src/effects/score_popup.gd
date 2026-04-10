## ScorePopup — Spawns animated floating score labels that drift upward and fade out.
## Each popup is a Label added to a parent node, tweened, then freed automatically.
class_name ScorePopup
extends RefCounted


const DEFAULT_RISE_DISTANCE: float = 80.0
const DEFAULT_DURATION: float = 0.8
const DEFAULT_FONT_SIZE: int = 24


## Create a floating popup label with text, color, and optional scale multiplier.
## The label is added to `parent`, animates upward while fading, then self-destructs.
func create_popup(parent: Control, text: String, position: Vector2, color: Color = Color.WHITE, scale_mult: float = 1.0) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.modulate = color
	label.z_index = 100
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var font_size: int = int(DEFAULT_FONT_SIZE * scale_mult)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)  # Use modulate for tinting

	# Offset so the label is centered on the position
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Pivot for scaling
	label.pivot_offset = Vector2(label.size.x / 2.0, label.size.y / 2.0)

	parent.add_child(label)

	_animate_popup(label, scale_mult)
	return label


## Create a score popup specifically for point values (e.g., "+50").
func create_score_popup(parent: Control, amount: int, position: Vector2, multiplier: float = 1.0) -> Label:
	var text: String = "+%d" % amount if amount >= 0 else "%d" % amount
	var color: Color = _score_color(amount, multiplier)
	var scale: float = _score_scale(multiplier)
	return create_popup(parent, text, position, color, scale)


## Create a radical bonus popup (e.g., radical name + bonus amount).
func create_radical_bonus_popup(parent: Control, radical: String, bonus: int, position: Vector2) -> Label:
	var text: String = "%s +%d" % [radical, bonus]
	return create_popup(parent, text, position, Color(0.4, 1.0, 0.8), 1.1)


func _animate_popup(label: Label, scale_mult: float) -> void:
	var start_pos: Vector2 = label.position
	var end_pos: Vector2 = start_pos + Vector2(0.0, -DEFAULT_RISE_DISTANCE * scale_mult)
	var duration: float = DEFAULT_DURATION

	# Initial scale pop
	label.scale = Vector2.ONE * 0.5

	var tween: Tween = label.create_tween()

	# Phase 1: Scale pop in
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "position", start_pos + Vector2(0.0, -DEFAULT_RISE_DISTANCE * 0.3), 0.15)

	# Phase 2: Drift upward while fading
	tween.set_parallel(false)
	tween.set_parallel(true)
	tween.tween_property(label, "position", end_pos, duration - 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, duration - 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "scale", Vector2.ONE * 0.7, duration - 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Clean up
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


func _score_color(amount: int, multiplier: float) -> Color:
	if multiplier >= 3.0:
		return Color(1.0, 0.8, 0.0)   # Gold for high multiplier
	elif multiplier >= 2.0:
		return Color(0.7, 0.2, 1.0)   # Purple
	elif amount > 0:
		return Color(0.3, 1.0, 0.3)   # Green for positive
	else:
		return Color(1.0, 0.3, 0.3)   # Red for negative


func _score_scale(multiplier: float) -> float:
	if multiplier >= 3.0:
		return 1.5
	elif multiplier >= 2.0:
		return 1.3
	elif multiplier >= 1.5:
		return 1.15
	return 1.0


