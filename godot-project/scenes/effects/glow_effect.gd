## GlowEffect — Pulsing glow overlay for card rarity effects and highlights.
## Uses a ColorRect that pulses in alpha. Configurable color and intensity.
class_name GlowEffect
extends Node2D

@onready var _glow_rect: ColorRect = $GlowRect if has_node("GlowRect") else null

@export var glow_color: Color = Color(1.0, 0.85, 0.0, 0.4)
@export var pulse_min_alpha: float = 0.1
@export var pulse_max_alpha: float = 0.5
@export var pulse_speed: float = 1.5
@export var glow_size: Vector2 = Vector2(120, 120)
@export var auto_play: bool = true
@export var loop_count: int = 0  ## 0 = infinite

var _tween: Tween
var _loop_iteration: int = 0


func _ready() -> void:
	_setup_glow_rect()
	if auto_play:
		play()


func setup(color: Color, intensity: float = 0.5, size: Vector2 = Vector2(120, 120)) -> void:
	glow_color = color
	pulse_max_alpha = intensity
	pulse_min_alpha = intensity * 0.2
	glow_size = size
	_setup_glow_rect()


func play() -> void:
	_kill_tween()
	_loop_iteration = 0
	_start_pulse()


func stop() -> void:
	_kill_tween()
	if _glow_rect:
		_glow_rect.modulate.a = 0.0


func set_glow_color(color: Color) -> void:
	glow_color = color
	if _glow_rect:
		_glow_rect.color = Color(color.r, color.g, color.b, 1.0)


func set_intensity(intensity: float) -> void:
	pulse_max_alpha = clampf(intensity, 0.0, 1.0)
	pulse_min_alpha = pulse_max_alpha * 0.2


func _setup_glow_rect() -> void:
	if _glow_rect == null:
		_glow_rect = ColorRect.new()
		_glow_rect.name = "GlowRect"
		add_child(_glow_rect)

	_glow_rect.color = Color(glow_color.r, glow_color.g, glow_color.b, 1.0)
	_glow_rect.size = glow_size
	_glow_rect.position = -glow_size / 2.0
	_glow_rect.modulate.a = pulse_min_alpha
	_glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _start_pulse() -> void:
	_kill_tween()

	if loop_count > 0 and _loop_iteration >= loop_count:
		_on_finished()
		return

	var half_duration := 1.0 / pulse_speed

	_tween = create_tween()
	_tween.tween_property(_glow_rect, "modulate:a", pulse_max_alpha, half_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_glow_rect, "modulate:a", pulse_min_alpha, half_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_callback(func() -> void:
		_loop_iteration += 1
		_start_pulse()
	)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _on_finished() -> void:
	# Fade out and self-destruct
	_kill_tween()
	_tween = create_tween()
	if _glow_rect:
		_tween.tween_property(_glow_rect, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(queue_free)
