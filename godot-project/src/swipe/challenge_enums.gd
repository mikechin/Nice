## ChallengeEnums — Constants and helpers for the challenge/answer system.
class_name ChallengeEnums
extends RefCounted

## Directions the player can swipe to select an answer.
## NONE represents a degenerate input (e.g. zero-magnitude vector) so callers
## don't get a silent default of RIGHT.
enum SwipeDirection { UP, DOWN, LEFT, RIGHT, NONE }

## How wrong answers are generated.
enum DistractorStrategy {
	SAME_TONE,         ## Same tone, different meaning
	SIMILAR_PINYIN,    ## Similar sounding pinyin
	SAME_RADICAL,      ## Shares a radical with the correct answer
	SAME_HSK_LEVEL,    ## Same HSK level (fallback)
	RANDOM             ## Pure random (last resort)
}

## Result of a single card challenge.
enum ChallengeResult { CORRECT, INCORRECT, SKIPPED }

const DIRECTION_LABELS: Dictionary = {
	SwipeDirection.UP: "up",
	SwipeDirection.DOWN: "down",
	SwipeDirection.LEFT: "left",
	SwipeDirection.RIGHT: "right",
	SwipeDirection.NONE: "none",
}

const DIRECTION_VECTORS: Dictionary = {
	SwipeDirection.UP: Vector2.UP,
	SwipeDirection.DOWN: Vector2.DOWN,
	SwipeDirection.LEFT: Vector2.LEFT,
	SwipeDirection.RIGHT: Vector2.RIGHT,
	SwipeDirection.NONE: Vector2.ZERO,
}

static func direction_from_vector(v: Vector2) -> SwipeDirection:
	if v == Vector2.ZERO:
		return SwipeDirection.NONE
	var abs_v := v.abs()
	if abs_v.y > abs_v.x:
		return SwipeDirection.UP if v.y < 0 else SwipeDirection.DOWN
	else:
		return SwipeDirection.LEFT if v.x < 0 else SwipeDirection.RIGHT

static func direction_to_string(d: SwipeDirection) -> String:
	return DIRECTION_LABELS.get(d, "unknown")
