## ComboText — Floating text effect showing combo count.
## Tweens upward and fades out, then self-destructs. Used on combo milestones.
class_name ComboText
extends Node2D

@onready var _label: Label = $Label if has_node("Label") else null

var combo_count: int = 0
var display_text: String = ""
var float_distance: float = 80.0
var duration: float = 1.0
var font_color: Color = Color(1.0, 0.85, 0.0)
var font_size: int = 32

var _tween: Tween


func _ready() -> void:
	if display_text.is_empty():
		display_text = "%d Combo!" % combo_count if combo_count > 0 else ""
	_setup_label()


func setup(count: int, color: Color = Color(1.0, 0.85, 0.0)) -> void:
	combo_count = count
	font_color = color

	# Escalate visual intensity with combo
	if count >= 50:
		display_text = "%d COMBO!!!" % count
		font_size = 48
	elif count >= 20:
		display_text = "%d COMBO!!" % count
		font_size = 40
	elif count >= 10:
		display_text = "%d Combo!" % count
		font_size = 36
	else:
		display_text = "%d Combo" % count
		font_size = 32

	_setup_label()


func play() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween().set_parallel(true)

	# Float upward
	var target_pos := position + Vector2(0, -float_distance)
	_tween.tween_property(self, "position", target_pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Scale up then back
	_tween.tween_property(self, "scale", Vector2(1.3, 1.3), duration * 0.2).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_property(self, "scale", Vector2.ONE, duration * 0.3)

	# Fade out in last third
	_tween.tween_property(self, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)

	# Clean up when done
	_tween.chain().tween_callback(_on_finished)


func _setup_label() -> void:
	if _label == null:
		# Create a label if none exists in the scene tree
		_label = Label.new()
		_label.name = "Label"
		add_child(_label)

	_label.text = display_text
	_label.add_theme_color_override("font_color", font_color)
	_label.add_theme_font_size_override("font_size", font_size)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Center the label on this node
	_label.position = Vector2(-100, -font_size / 2.0)
	_label.size = Vector2(200, float(font_size) + 8.0)


func _on_finished() -> void:
	queue_free()
