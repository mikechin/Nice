## CardEffects — Visual tween effects for card interactions.
## Creates and returns Tweens for correct/wrong answers, combos, tier promotions, and reveals.
class_name CardEffects
extends RefCounted


## Green flash + scale bounce for a correct answer.
func create_correct_tween(node: Control) -> Tween:
	var tween: Tween = node.create_tween()
	var original_modulate: Color = node.modulate
	var original_scale: Vector2 = node.scale
	var center: Vector2 = node.pivot_offset

	# Ensure pivot is centered for scaling
	if center == Vector2.ZERO:
		node.pivot_offset = node.size / 2.0

	tween.set_parallel(true)

	# Flash green
	tween.tween_property(node, "modulate", Color(0.3, 1.0, 0.3), 0.08)
	# Scale up
	tween.tween_property(node, "scale", original_scale * 1.15, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	tween.set_parallel(false)
	tween.set_parallel(true)
	# Return to original color
	tween.tween_property(node, "modulate", original_modulate, 0.2)
	# Bounce back to original scale
	tween.tween_property(node, "scale", original_scale, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	return tween


## Red shake for a wrong answer.
func create_wrong_tween(node: Control) -> Tween:
	var tween: Tween = node.create_tween()
	var original_pos: Vector2 = node.position
	var original_modulate: Color = node.modulate
	var shake_amount: float = 8.0

	# Flash red
	tween.tween_property(node, "modulate", Color(1.0, 0.3, 0.3), 0.05)

	# Rapid horizontal shake
	for i in range(4):
		var direction: float = -1.0 if i % 2 == 0 else 1.0
		var offset := Vector2(shake_amount * direction, 0.0)
		tween.tween_property(node, "position", original_pos + offset, 0.04)

	# Return to original position and color
	tween.tween_property(node, "position", original_pos, 0.04)
	tween.tween_property(node, "modulate", original_modulate, 0.15)

	return tween


## Combo burst — intensity scales with combo count.
func create_combo_burst(node: Control, combo: int) -> Tween:
	var tween: Tween = node.create_tween()
	var original_scale: Vector2 = node.scale

	if node.pivot_offset == Vector2.ZERO:
		node.pivot_offset = node.size / 2.0

	# Scale burst proportional to combo tier
	var burst_scale: float = 1.0
	if combo >= 50:
		burst_scale = 1.4
	elif combo >= 20:
		burst_scale = 1.3
	elif combo >= 10:
		burst_scale = 1.2
	elif combo >= 5:
		burst_scale = 1.15
	else:
		burst_scale = 1.1

	# Determine combo glow color
	var glow_color: Color = _combo_color(combo)

	tween.set_parallel(true)
	tween.tween_property(node, "scale", original_scale * burst_scale, 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "modulate", glow_color, 0.08)

	tween.set_parallel(false)
	tween.set_parallel(true)
	tween.tween_property(node, "scale", original_scale, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(node, "modulate", Color.WHITE, 0.25)

	return tween


## Tier promotion — celebratory scale + color shift from old tier to new tier.
func create_tier_promotion(node: Control, old_tier: int, new_tier: int) -> Tween:
	var tween: Tween = node.create_tween()
	var original_scale: Vector2 = node.scale

	if node.pivot_offset == Vector2.ZERO:
		node.pivot_offset = node.size / 2.0

	var old_color: Color = CollectionEnums.tier_color(old_tier as CollectionEnums.CardTier)
	var new_color: Color = CollectionEnums.tier_color(new_tier as CollectionEnums.CardTier)

	# Start at old tier color
	node.modulate = old_color

	# Phase 1: Pulse outward with white flash
	tween.tween_property(node, "scale", original_scale * 1.3, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(node, "modulate", Color.WHITE, 0.1)

	# Phase 2: Contract slightly and shift to new tier color
	tween.set_parallel(true)
	tween.tween_property(node, "scale", original_scale * 0.9, 0.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(node, "modulate", new_color, 0.1)

	# Phase 3: Final bounce to normal scale, then fade to white
	tween.set_parallel(false)
	tween.tween_property(node, "scale", original_scale, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(node, "modulate", Color.WHITE, 0.4)

	return tween


## New card reveal — fade in from transparent + scale up from small.
func create_new_card_reveal(node: Control) -> Tween:
	var tween: Tween = node.create_tween()
	var target_scale: Vector2 = node.scale

	if node.pivot_offset == Vector2.ZERO:
		node.pivot_offset = node.size / 2.0

	# Start invisible and small
	node.modulate.a = 0.0
	node.scale = target_scale * 0.3

	tween.set_parallel(true)
	# Fade in
	tween.tween_property(node, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Scale up with overshoot
	tween.tween_property(node, "scale", target_scale, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Brief golden glow after reveal
	tween.set_parallel(false)
	tween.tween_property(node, "modulate", Color(1.0, 0.9, 0.5), 0.15)
	tween.tween_property(node, "modulate", Color.WHITE, 0.25)

	return tween


## Determine glow color based on combo count.
func _combo_color(combo: int) -> Color:
	if combo >= 50:
		return Color(1.0, 0.8, 0.0)   # Gold
	elif combo >= 20:
		return Color(0.7, 0.2, 1.0)   # Purple
	elif combo >= 10:
		return Color(0.2, 0.6, 1.0)   # Blue
	elif combo >= 5:
		return Color(0.2, 1.0, 0.4)   # Green
	return Color(1.0, 1.0, 1.0)       # White
