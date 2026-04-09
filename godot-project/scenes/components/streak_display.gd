## StreakDisplay — Shows the player's daily streak with a flame icon and day count.
## Animates on streak updates. Gray when streak is 0.
class_name StreakDisplay
extends Control

@onready var _flame_label: Label = $FlameLabel if has_node("FlameLabel") else null
@onready var _count_label: Label = $CountLabel if has_node("CountLabel") else null
@onready var _days_label: Label = $DaysLabel if has_node("DaysLabel") else null

var _current_streak: int = 0
var _tween: Tween

const FLAME_ACTIVE_COLOR := Color(1.0, 0.5, 0.0)
const FLAME_INACTIVE_COLOR := Color(0.4, 0.4, 0.4)
const COUNT_ACTIVE_COLOR := Color(1.0, 0.85, 0.0)
const COUNT_INACTIVE_COLOR := Color(0.5, 0.5, 0.5)


func _ready() -> void:
	SignalBus.streak_updated.connect(_on_streak_updated)
	SignalBus.streak_broken.connect(_on_streak_broken)
	_current_streak = GameState.daily_streak


func _exit_tree() -> void:
	SignalBus.streak_updated.disconnect(_on_streak_updated)
	SignalBus.streak_broken.disconnect(_on_streak_broken)
	_update_display()


func set_streak(days: int) -> void:
	var old_streak := _current_streak
	_current_streak = days
	_update_display()
	if days > old_streak and days > 0:
		_animate_streak_up()


func get_streak() -> int:
	return _current_streak


func _update_display() -> void:
	var is_active: bool = _current_streak > 0

	if _flame_label:
		_flame_label.text = "F"
		_flame_label.add_theme_color_override("font_color",
			FLAME_ACTIVE_COLOR if is_active else FLAME_INACTIVE_COLOR
		)

	if _count_label:
		_count_label.text = str(_current_streak)
		_count_label.add_theme_color_override("font_color",
			COUNT_ACTIVE_COLOR if is_active else COUNT_INACTIVE_COLOR
		)

	if _days_label:
		if _current_streak == 1:
			_days_label.text = "day"
		else:
			_days_label.text = "days"


func _animate_streak_up() -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.15)


func _animate_streak_broken() -> void:
	_kill_tween()
	_tween = create_tween()

	# Shake
	var orig_pos := position
	_tween.tween_property(self, "position", orig_pos + Vector2(6, 0), 0.04)
	_tween.tween_property(self, "position", orig_pos - Vector2(6, 0), 0.04)
	_tween.tween_property(self, "position", orig_pos + Vector2(3, 0), 0.04)
	_tween.tween_property(self, "position", orig_pos, 0.04)

	# Fade to gray
	if _flame_label:
		_tween.parallel().tween_property(_flame_label, "modulate", Color(0.5, 0.5, 0.5), 0.3)
		_tween.tween_callback(func() -> void:
			if _flame_label:
				_flame_label.modulate = Color.WHITE
		)


func _on_streak_updated(days: int) -> void:
	set_streak(days)


func _on_streak_broken() -> void:
	_current_streak = 0
	_update_display()
	_animate_streak_broken()


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
