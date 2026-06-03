## CrawlRoom — the spatial dungeon-crawl screen (Phase 3, crawler pivot 2026-06-03).
##
## ALttP-style top-down room you walk around in. This is STEP 1 of the spatial
## vertical slice: movement + wall collision only. Still to come (combat and the
## M3 economy are reused wholesale, so this layer only owns moving the hero
## through space):
##   - FFVI-style random encounters: each step rolls → scene-transition to the
##     existing ATB battle → a victory/spoils screen showing the drops.
##   - Wardens guarding the extraction door (contact-based; the player chooses
##     when to engage).
##
## Built in code (matches the combat / dungeon-map screens). Node2D world: the
## single room fits the 1920×1080 landscape frame, so no camera yet. Input is via
## the built-in ui_* actions (arrow keys AND gamepad d-pad), so it's already
## control-scheme-agnostic — a touch joystick slots in here once a platform is
## chosen.
class_name CrawlRoom
extends Node2D

const HERO_SPEED := 430.0
const HERO_SIZE := Vector2(74, 98)              # ~half the combat hero box (placeholder)
const HERO_COLOR := Color(0.30, 0.46, 0.62)     # matches the combat hero
const ROOM_RECT := Rect2(200, 170, 1520, 740)   # interior the hero can roam
const WALL_THICK := 26.0
const FLOOR_COLOR := Color(0.12, 0.11, 0.15)
const WALL_COLOR := Color(0.34, 0.31, 0.42)

var _hero: CharacterBody2D


func _ready() -> void:
	# Self-starting (debug entry): a run gives later increments depth + a haul to
	# carry. Movement itself doesn't need it, but the encounter/extract steps will.
	if not RunState.has_active_run():
		RunState.begin_run()
	_build_floor()
	_build_walls()
	_build_hero()
	_build_hud()


func _physics_process(_delta: float) -> void:
	if _hero == null:
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_hero.velocity = dir * HERO_SPEED
	_hero.move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		RunState.clear_run()
		SignalBus.screen_transition_requested.emit("main_menu")


# -- geometry (pure, testable) -----------------------------------------------

## The four wall rects bounding `room` (order: top, bottom, left, right). Each
## sits just outside the interior so the hero is fenced in. Pure for tests.
static func wall_rects(room: Rect2, thickness: float) -> Array[Rect2]:
	var t := thickness
	return [
		Rect2(room.position.x - t, room.position.y - t, room.size.x + t * 2.0, t),  # top
		Rect2(room.position.x - t, room.end.y, room.size.x + t * 2.0, t),           # bottom
		Rect2(room.position.x - t, room.position.y, t, room.size.y),                # left
		Rect2(room.end.x, room.position.y, t, room.size.y),                         # right
	]


## The hero's spawn — bottom-center of the room, as if walking in from a door.
static func spawn_point(room: Rect2, hero_size: Vector2) -> Vector2:
	return Vector2(room.position.x + room.size.x * 0.5, room.end.y - hero_size.y)


# -- build -------------------------------------------------------------------

func _build_floor() -> void:
	var floor_rect := ColorRect.new()
	floor_rect.color = FLOOR_COLOR
	floor_rect.position = ROOM_RECT.position
	floor_rect.size = ROOM_RECT.size
	add_child(floor_rect)


func _build_walls() -> void:
	for r in wall_rects(ROOM_RECT, WALL_THICK):
		_add_wall(r)


func _add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5     # origin = rect center
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	body.add_child(shape)
	var vis := ColorRect.new()
	vis.color = WALL_COLOR
	vis.size = rect.size
	vis.position = -rect.size * 0.5                     # center the visual on the origin
	body.add_child(vis)
	add_child(body)


func _build_hero() -> void:
	_hero = CharacterBody2D.new()
	_hero.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING   # top-down: no gravity/floor
	_hero.position = spawn_point(ROOM_RECT, HERO_SIZE)
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = HERO_SIZE
	shape.shape = rs
	_hero.add_child(shape)
	var vis := ColorRect.new()
	vis.color = HERO_COLOR
	vis.size = HERO_SIZE
	vis.position = -HERO_SIZE * 0.5
	_hero.add_child(vis)
	add_child(_hero)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "Arrow keys / D-pad to move    ·    Esc → Menu"
	label.add_theme_font_size_override("font_size", 24)
	label.position = Vector2(40, 34)
	layer.add_child(label)
