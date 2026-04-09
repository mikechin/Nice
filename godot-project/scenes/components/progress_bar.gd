## GameProgressBar — Custom progress bar showing completion fraction with a label.
## Displays "current / total" and smoothly animates fill on updates.
class_name GameProgressBar
extends Control

@onready var _bar_background: ColorRect = $Background if has_node("Background") else null
@onready var _bar_fill: ColorRect = $Fill if has_node("Fill") else null
@onready var _fraction_label: Label = $FractionLabel if has_node("FractionLabel") else null
@onready var _percentage_label: Label = $PercentageLabel if has_node("PercentageLabel") else null

var _current: int = 0
var _maximum: int = 1
var _fill_ratio: float = 0.0
var _tween: Tween

@export var fill_color: Color = Color(0.3, 0.8, 0.3)
@export var background_color: Color = Color(0.2, 0.2, 0.2, 0.6)
@export var animate_fill: bool = true
@export var show_percentage: bool = false


func _ready() -> void:
	_warn_missing_nodes()
	if _bar_background:
		_bar_background.color = background_color
	if _bar_fill:
		_bar_fill.color = fill_color
	_update_display()


func set_progress(current: int, maximum: int) -> void:
	_current = maxi(0, current)
	_maximum = maxi(1, maximum)
	var target_ratio: float = float(_current) / float(_maximum)

	if animate_fill and _bar_fill:
		_animate_fill(target_ratio)
	else:
		_fill_ratio = target_ratio
		_update_display()


func set_progress_float(ratio: float) -> void:
	_fill_ratio = clampf(ratio, 0.0, 1.0)
	_current = roundi(_fill_ratio * _maximum)
	_update_display()


func get_current() -> int:
	return _current


func get_maximum() -> int:
	return _maximum


func get_fill_ratio() -> float:
	return _fill_ratio


func _update_display() -> void:
	# Update fill width
	if _bar_fill and _bar_background:
		var bar_width: float = _bar_background.size.x
		_bar_fill.size.x = bar_width * _fill_ratio
		_bar_fill.size.y = _bar_background.size.y

	if _fraction_label:
		_fraction_label.text = "%d / %d" % [_current, _maximum]

	if _percentage_label:
		_percentage_label.visible = show_percentage
		if show_percentage:
			_percentage_label.text = "%d%%" % roundi(_fill_ratio * 100.0)


func _animate_fill(target_ratio: float) -> void:
	_kill_tween()
	_tween = create_tween()

	var from_ratio := _fill_ratio
	_tween.tween_method(func(val: float) -> void:
		_fill_ratio = val
		_current = roundi(val * float(_maximum))
		_update_display()
	, from_ratio, target_ratio, 0.3)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _warn_missing_nodes() -> void:
	if _bar_background == null:
		push_warning("progress_bar.gd: missing node _bar_background")
	if _bar_fill == null:
		push_warning("progress_bar.gd: missing node _bar_fill")
	if _fraction_label == null:
		push_warning("progress_bar.gd: missing node _fraction_label")
	if _percentage_label == null:
		push_warning("progress_bar.gd: missing node _percentage_label")
