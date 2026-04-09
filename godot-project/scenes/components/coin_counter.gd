## CoinCounter — Displays the player's coin count with animated changes.
## Listens to coins_changed signal and tweens between old and new values.
class_name CoinCounter
extends Control

@onready var _count_label: Label = $CountLabel if has_node("CountLabel") else null
@onready var _icon_label: Label = $IconLabel if has_node("IconLabel") else null
@onready var _change_label: Label = $ChangeLabel if has_node("ChangeLabel") else null

var _displayed_count: int = 0
var _target_count: int = 0
var _tween: Tween


func _ready() -> void:
	SignalBus.coins_changed.connect(_on_coins_changed)
	_displayed_count = GameState.total_coins
	_target_count = _displayed_count
	_update_label()


func set_count(count: int) -> void:
	var old_count := _displayed_count
	_target_count = count
	if old_count != count:
		_animate_change(count - old_count)
	else:
		_displayed_count = count
		_update_label()


func get_count() -> int:
	return _target_count


func _update_label() -> void:
	if _count_label:
		_count_label.text = str(_displayed_count)
	if _icon_label:
		_icon_label.text = "C"


func _animate_change(delta: int) -> void:
	_kill_tween()
	_tween = create_tween()

	# Show change amount
	if _change_label:
		_change_label.visible = true
		_change_label.modulate.a = 1.0
		if delta > 0:
			_change_label.text = "+%d" % delta
			_change_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		else:
			_change_label.text = str(delta)
			_change_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	# Count up/down animation
	var start_val := _displayed_count
	var end_val := _target_count
	var duration := clampf(absf(float(delta)) / 100.0, 0.2, 0.8)

	_tween.tween_method(func(val: float) -> void:
		_displayed_count = roundi(val)
		_update_label()
	, float(start_val), float(end_val), duration)

	# Bounce the counter
	_tween.parallel().tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.1)

	# Fade out change label
	if _change_label:
		_tween.parallel().tween_property(_change_label, "modulate:a", 0.0, 1.0)
		_tween.tween_callback(func() -> void:
			if _change_label:
				_change_label.visible = false
		)


func _on_coins_changed(amount: int, total: int) -> void:
	_target_count = total
	_animate_change(amount)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
