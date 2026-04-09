## ScreenEffects — Screen transition effects using Tweens.
## Provides fade and slide transitions for UI screens.
class_name ScreenEffects
extends RefCounted


## Fade a control in from transparent to fully opaque.
func fade_in(node: Control, duration: float = 0.3) -> Tween:
	node.modulate.a = 0.0
	node.visible = true

	var tween: Tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	return tween


## Fade a control out from fully opaque to transparent.
func fade_out(node: Control, duration: float = 0.3) -> Tween:
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func() -> void: node.visible = false)
	return tween


## Slide a control in from an off-screen direction.
## `direction` is a unit vector indicating where the node starts relative to its final position.
## Example: Vector2(-1, 0) means slide in from the left.
func slide_in_from(node: Control, direction: Vector2, duration: float = 0.4) -> Tween:
	var final_position: Vector2 = node.position
	var viewport_size: Vector2 = _get_viewport_size(node)
	var offset := Vector2(direction.x * viewport_size.x, direction.y * viewport_size.y)

	node.position = final_position + offset
	node.visible = true

	var tween: Tween = node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "position", final_position, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	# Slight fade for polish
	node.modulate.a = 0.0
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.5)
	return tween


## Slide a control out toward a direction, then hide it.
## `direction` is a unit vector indicating where the node moves to.
## Example: Vector2(1, 0) means slide out to the right.
func slide_out_to(node: Control, direction: Vector2, duration: float = 0.4) -> Tween:
	var start_position: Vector2 = node.position
	var viewport_size: Vector2 = _get_viewport_size(node)
	var target := start_position + Vector2(direction.x * viewport_size.x, direction.y * viewport_size.y)

	var tween: Tween = node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "position", target, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	# Fade out during slide
	tween.tween_property(node, "modulate:a", 0.0, duration * 0.8)

	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		node.visible = false
		node.position = start_position
		node.modulate.a = 1.0
	)
	return tween


## Cross-fade between two controls: fade out `from_node`, fade in `to_node`.
func cross_fade(from_node: Control, to_node: Control, duration: float = 0.3) -> Tween:
	to_node.modulate.a = 0.0
	to_node.visible = true

	var tween: Tween = from_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(from_node, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(to_node, "modulate:a", 1.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	tween.set_parallel(false)
	tween.tween_callback(func() -> void: from_node.visible = false)
	return tween


## Slide-swap: slide `from_node` out in one direction, slide `to_node` in from the opposite.
func slide_swap(from_node: Control, to_node: Control, direction: Vector2, duration: float = 0.4) -> Tween:
	var viewport_size: Vector2 = _get_viewport_size(from_node)
	var offset := Vector2(direction.x * viewport_size.x, direction.y * viewport_size.y)

	var from_start: Vector2 = from_node.position
	var to_final: Vector2 = to_node.position

	to_node.position = to_final - offset
	to_node.visible = true

	var tween: Tween = from_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(from_node, "position", from_start + offset, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(to_node, "position", to_final, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		from_node.visible = false
		from_node.position = from_start
	)
	return tween


func _get_viewport_size(node: Control) -> Vector2:
	var viewport: Viewport = node.get_viewport()
	if viewport:
		return viewport.get_visible_rect().size
	return Vector2(1920.0, 1080.0)  # Fallback
