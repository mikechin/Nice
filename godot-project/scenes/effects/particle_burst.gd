## ParticleBurst — Configurable particle burst effect using procedural particles.
## Spawns colored squares that fly outward with gravity and fade. Used for
## card reveals and tier promotions.
class_name ParticleBurst
extends Node2D

@export var burst_color: Color = Color(1.0, 0.85, 0.0)
@export var particle_count: int = 12
@export var spread_angle: float = 360.0  ## degrees
@export var min_speed: float = 100.0
@export var max_speed: float = 250.0
@export var gravity: float = 200.0
@export var lifetime: float = 0.8
@export var particle_size: float = 6.0
@export var color_variation: float = 0.15
@export var auto_play: bool = true

var _particles: Array[Dictionary] = []
var _elapsed: float = 0.0
var _is_playing: bool = false


func _ready() -> void:
	if auto_play:
		play()


func setup(color: Color, count: int = 12, spread: float = 360.0) -> void:
	burst_color = color
	particle_count = count
	spread_angle = spread


func play() -> void:
	_particles.clear()
	_elapsed = 0.0
	_is_playing = true

	var spread_rad := deg_to_rad(spread_angle)
	var base_angle := -spread_rad / 2.0

	for i in particle_count:
		# Random direction within spread
		var angle: float
		if spread_angle >= 360.0:
			angle = randf() * TAU
		else:
			angle = base_angle + randf() * spread_rad

		var speed := randf_range(min_speed, max_speed)
		var velocity := Vector2(cos(angle), sin(angle)) * speed

		# Color variation
		var r_offset := randf_range(-color_variation, color_variation)
		var g_offset := randf_range(-color_variation, color_variation)
		var b_offset := randf_range(-color_variation, color_variation)
		var p_color := Color(
			clampf(burst_color.r + r_offset, 0.0, 1.0),
			clampf(burst_color.g + g_offset, 0.0, 1.0),
			clampf(burst_color.b + b_offset, 0.0, 1.0),
			1.0
		)

		var p_size := particle_size * randf_range(0.5, 1.5)

		_particles.append({
			"pos": Vector2.ZERO,
			"vel": velocity,
			"color": p_color,
			"size": p_size,
			"rotation": randf() * TAU,
			"rot_speed": randf_range(-5.0, 5.0),
		})

	set_process(true)
	queue_redraw()


func stop() -> void:
	_is_playing = false
	_particles.clear()
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	if not _is_playing:
		return

	_elapsed += delta

	if _elapsed >= lifetime:
		_on_finished()
		return

	# Update particles
	for p in _particles:
		p["vel"] = p["vel"] + Vector2(0, gravity) * delta
		p["pos"] = p["pos"] + p["vel"] * delta
		p["rotation"] = p["rotation"] + p["rot_speed"] * delta

	queue_redraw()


func _draw() -> void:
	if not _is_playing or _particles.is_empty():
		return

	var alpha_factor: float = 1.0 - clampf(_elapsed / lifetime, 0.0, 1.0)
	# Ease out the fade
	alpha_factor = alpha_factor * alpha_factor

	for p in _particles:
		var p_pos: Vector2 = p["pos"]
		var p_color: Color = p["color"]
		p_color.a = alpha_factor
		var p_size: float = p["size"] * (0.5 + 0.5 * alpha_factor)

		var rect := Rect2(p_pos - Vector2(p_size, p_size) / 2.0, Vector2(p_size, p_size))
		draw_rect(rect, p_color)


func _on_finished() -> void:
	_is_playing = false
	_particles.clear()
	set_process(false)
	queue_redraw()
	queue_free()
