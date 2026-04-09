## ComboCounter — Displays the current combo count with milestone animations.
## Listens to SignalBus for combo changes and plays escalating effects.
class_name ComboCounter
extends Control

@onready var _count_label: Label = $CountLabel if has_node("CountLabel") else null
@onready var _combo_label: Label = $ComboLabel if has_node("ComboLabel") else null
@onready var _milestone_label: Label = $MilestoneLabel if has_node("MilestoneLabel") else null

var _current_combo: int = 0
var _tween: Tween


func _ready() -> void:
	SignalBus.combo_incremented.connect(_on_combo_incremented)
	SignalBus.combo_broken.connect(_on_combo_broken)
	SignalBus.combo_milestone.connect(_on_combo_milestone)
	_update_display()


func _exit_tree() -> void:
	SignalBus.combo_incremented.disconnect(_on_combo_incremented)
	SignalBus.combo_broken.disconnect(_on_combo_broken)
	SignalBus.combo_milestone.disconnect(_on_combo_milestone)


func set_combo(count: int) -> void:
	_current_combo = count
	_update_display()
	if count > 0:
		_animate_increment()


func get_combo() -> int:
	return _current_combo


func _update_display() -> void:
	if _count_label:
		_count_label.text = str(_current_combo)
	if _combo_label:
		_combo_label.visible = _current_combo > 0
		_combo_label.text = "COMBO"

	# Scale color intensity with combo
	if _count_label and _current_combo > 0:
		var intensity: float = clampf(float(_current_combo) / 50.0, 0.0, 1.0)
		var color := Color(1.0, 1.0 - intensity * 0.5, 1.0 - intensity, 1.0)
		_count_label.add_theme_color_override("font_color", color)
	elif _count_label:
		_count_label.add_theme_color_override("font_color", Color.WHITE)

	visible = _current_combo > 0


func _animate_increment() -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.08)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.1)


func _animate_milestone(milestone: int) -> void:
	_kill_tween()
	_tween = create_tween()

	# Flash the milestone label
	if _milestone_label:
		_milestone_label.visible = true
		_milestone_label.text = "%d!" % milestone
		_milestone_label.modulate.a = 1.0

	# Big bounce
	_tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.15)

	# Fade out milestone text
	if _milestone_label:
		_tween.parallel().tween_property(_milestone_label, "modulate:a", 0.0, 0.8)
		_tween.tween_callback(func() -> void:
			if _milestone_label:
				_milestone_label.visible = false
		)


func _animate_break() -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(func() -> void:
		_current_combo = 0
		_update_display()
		modulate.a = 1.0
	)


func _on_combo_incremented(combo_count: int) -> void:
	_current_combo = combo_count
	_update_display()
	_animate_increment()


func _on_combo_broken(final_count: int) -> void:
	if final_count > 0:
		_animate_break()
	else:
		_current_combo = 0
		_update_display()


func _on_combo_milestone(milestone: int) -> void:
	_animate_milestone(milestone)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
