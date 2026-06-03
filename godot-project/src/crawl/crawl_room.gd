## CrawlRoom — the spatial dungeon-crawl screen (Phase 3, crawler pivot 2026-06-03).
##
## ALttP-style top-down space you walk around in (FFVI for the battles):
##   - Two rooms joined by a corridor — a start room and a far room — laid out
##     wider than the 1920×1080 frame, so a hero-following Camera2D scrolls the
##     view as you cross. Walls fence the rooms; the corridor mouth is the only
##     way between them.
##   - Every step accrues toward a randomized threshold → a **random encounter**:
##     the screen swaps to the existing ATB battle, whose victory banner is the
##     "spoils", then returns here (the hero restored where they stood).
##   - The far room holds the **extraction door**, guarded by a **Warden**
##     (contact-based): walk into it and press Enter to choose the fight. Beating
##     it opens the door.
##   - Walk into the open door → extract (bank the haul) → results.
##
## Combat + the M3 economy are reused unchanged — this screen only owns moving
## through space and deciding which fight to launch. State that must survive the
## crawl→battle→crawl scene swaps lives on RunState (run = HP/haul/economy,
## CrawlState = hero position + warden status). Built in code; Node2D world.
## Input via the built-in ui_* actions (keyboard + gamepad), so it's already
## control-scheme-agnostic.
class_name CrawlRoom
extends Node2D

const HERO_SPEED := 430.0
const HERO_SIZE := Vector2(74, 98)              # ~half the combat hero box (placeholder)
const HERO_COLOR := Color(0.30, 0.46, 0.62)
# The world is two rooms wide. ROOM_RECT is the start room (hero spawns here);
# ROOM_B is the far room holding the exit + warden; CORRIDOR bridges the gap
# between them. The whole span (~3.5k px) is far wider than the 1920 viewport, so
# the camera scrolls as you walk end to end.
const ROOM_RECT := Rect2(200, 170, 1520, 740)
const ROOM_B := Rect2(2120, 170, 1520, 740)
const CORRIDOR := Rect2(1720, 420, 400, 240)
const WALL_THICK := 26.0
const FLOOR_COLOR := Color(0.12, 0.11, 0.15)
const CORRIDOR_COLOR := Color(0.10, 0.09, 0.13)   # a shade dimmer — reads as a passage
const VOID_COLOR := Color(0.04, 0.038, 0.055)     # backdrop beyond the rooms
const WALL_COLOR := Color(0.34, 0.31, 0.42)
const CAMERA_SMOOTH_SPEED := 7.0

# Pixels of movement between random encounters (rolled per interval).
const ENCOUNTER_MIN_DIST := 750.0
const ENCOUNTER_MAX_DIST := 1550.0

const WARDEN_SIZE := Vector2(98, 116)
const WARDEN_COLOR := Color(0.58, 0.30, 0.36)
const DOOR_SIZE := Vector2(176, 84)
const DOOR_LOCKED_COLOR := Color(0.48, 0.22, 0.24)
const DOOR_OPEN_COLOR := Color(0.30, 0.62, 0.38)

var _cs: CrawlState
var _hero: CharacterBody2D
var _camera: Camera2D
var _warden: Area2D
var _door: Area2D
var _status: Label
var _prompt: Label
var _bag_button: Button
var _bag: LootBagOverlay
var _rng: RandomNumberGenerator

var _busy: bool = false                  # true while a scene swap / extract is in flight
var _bag_open: bool = false              # true while the loot bag overlay is up
var _warden_in_range: bool = false
var _distance_accum: float = 0.0
var _next_encounter_at: float = 0.0


func _ready() -> void:
	if not RunState.has_active_run():
		RunState.begin_run()
	_cs = RunState.crawl
	if _cs == null:
		_cs = CrawlState.new()
		RunState.crawl = _cs
	# Returning here alive after a warden fight means the warden was beaten
	# (death routes to results, never back here), so the door is now open.
	if _cs.warden_fight_pending:
		_cs.warden_defeated = true
		_cs.warden_fight_pending = false

	_rng = RandomNumberGenerator.new()
	_rng.randomize()

	_build_backdrop()
	_build_floor()
	_build_walls()
	_build_door()
	if not _cs.warden_defeated:
		_build_warden()
	_build_hero()
	_build_camera()
	_build_hud()
	_build_bag()
	_roll_next_encounter()
	# Returning from a battle with more loot than the bag holds forces a triage
	# right here, before the player walks on.
	if RunState.run != null and RunState.run.needs_triage():
		_open_bag(true)


func _physics_process(delta: float) -> void:
	if _busy or _bag_open or _hero == null:
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_hero.velocity = dir * HERO_SPEED
	_hero.move_and_slide()
	_update_status()
	if dir != Vector2.ZERO:
		_distance_accum += _hero.velocity.length() * delta
		if _distance_accum >= _next_encounter_at:
			_trigger_encounter()


func _unhandled_input(event: InputEvent) -> void:
	# While the bag is up it owns input (close keys, etc.) — don't move or quit.
	if _bag_open:
		return
	if event.is_action_pressed("ui_cancel"):
		RunState.clear_run()
		SignalBus.screen_transition_requested.emit("main_menu")
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_B and not _busy:
		_open_bag(false)
		# Consume it so the overlay (now open) doesn't read the same B and close.
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") and _warden_in_range and not _busy:
		_engage_warden()


# -- fight launches ----------------------------------------------------------

func _roll_next_encounter() -> void:
	_distance_accum = 0.0
	_next_encounter_at = _rng.randf_range(ENCOUNTER_MIN_DIST, ENCOUNTER_MAX_DIST)


## A random encounter: an ordinary mob fight. Save where we stand, then swap to
## the battle, which returns here.
func _trigger_encounter() -> void:
	_busy = true
	_cs.save_hero(_hero.position)
	RunState.combat_return_screen = "crawl"
	RunState.enter_room(_make_room(DungeonEnums.RoomType.ENCOUNTER, "Ambush"))
	AudioManager.play_sfx("button_tap")          # placeholder encounter sting
	SignalBus.screen_transition_requested.emit("combat")


## The warden fight: a chosen elite battle. Flag it so that, on returning alive,
## we know the warden is down and the door should open.
func _engage_warden() -> void:
	_busy = true
	_cs.save_hero(_hero.position)
	_cs.warden_fight_pending = true
	RunState.combat_return_screen = "crawl"
	RunState.enter_room(_make_room(DungeonEnums.RoomType.ELITE, "Warden"))
	SignalBus.screen_transition_requested.emit("combat")


## Bank the haul and end the run. The interactive carry-cap triage UI lives on
## the node-map screen; here we auto-keep the best N for now (a triage step at
## the door is a near-term follow-up).
func _extract() -> void:
	_busy = true
	var run := RunState.run
	run.extract()
	GameState.bank_haul(run.banked_haul(), run.shattered_haul())
	GameState.end_run(run.to_summary())
	RunState.clear_run()
	SignalBus.screen_transition_requested.emit("results")


func _make_room(type: DungeonEnums.RoomType, label: String) -> RoomNode:
	# An ad-hoc room so combat builds the right mobs (ELITE→Warden, else mobs)
	# and draws at the run's depth. The crawl doesn't traverse the RunMap graph.
	return RoomNode.create(0, type, RunState.run.depth, label, [])


# -- warden / door contact ---------------------------------------------------

func _on_warden_body_entered(body: Node) -> void:
	if body == _hero:
		_warden_in_range = true
		if _prompt:
			_prompt.text = "⚔  Press Enter to face the Warden"
			_prompt.visible = true


func _on_warden_body_exited(body: Node) -> void:
	if body == _hero:
		_warden_in_range = false
		if _prompt:
			_prompt.visible = false


func _on_door_body_entered(body: Node) -> void:
	if body == _hero and _cs.warden_defeated and not _busy:
		_extract()


# -- build -------------------------------------------------------------------

## A large dark plate behind everything so the area the camera reveals beyond the
## rooms (the world is shorter than the viewport vertically) reads as void, not a
## rendering gap.
func _build_backdrop() -> void:
	var top_left := Vector2(ROOM_RECT.position.x - WALL_THICK, ROOM_RECT.position.y - WALL_THICK) - Vector2(900, 900)
	var bottom_right := Vector2(ROOM_B.end.x + WALL_THICK, ROOM_B.end.y + WALL_THICK) + Vector2(900, 900)
	var bd := ColorRect.new()
	bd.color = VOID_COLOR
	bd.position = top_left
	bd.size = bottom_right - top_left
	add_child(bd)


func _build_floor() -> void:
	_add_floor(ROOM_RECT, FLOOR_COLOR)
	_add_floor(CORRIDOR, CORRIDOR_COLOR)
	_add_floor(ROOM_B, FLOOR_COLOR)


func _add_floor(rect: Rect2, color: Color) -> void:
	var fr := ColorRect.new()
	fr.color = color
	fr.position = rect.position
	fr.size = rect.size
	add_child(fr)


func _build_walls() -> void:
	for r in world_wall_rects(ROOM_RECT, ROOM_B, CORRIDOR, WALL_THICK):
		_add_wall(r)


func _add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	body.add_child(shape)
	var vis := ColorRect.new()
	vis.color = WALL_COLOR
	vis.size = rect.size
	vis.position = -rect.size * 0.5
	body.add_child(vis)
	add_child(body)


func _build_door() -> void:
	_door = Area2D.new()
	# Just inside the far room's top wall, centered — the hero crosses the whole
	# world and walks up to it.
	_door.position = Vector2(ROOM_B.position.x + ROOM_B.size.x * 0.5, ROOM_B.position.y + DOOR_SIZE.y * 0.5)
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = DOOR_SIZE
	shape.shape = rs
	_door.add_child(shape)
	var vis := ColorRect.new()
	vis.color = DOOR_OPEN_COLOR if _cs.warden_defeated else DOOR_LOCKED_COLOR
	vis.size = DOOR_SIZE
	vis.position = -DOOR_SIZE * 0.5
	_door.add_child(vis)
	var tag := Label.new()
	tag.text = "EXIT" if _cs.warden_defeated else "EXIT (locked)"
	tag.add_theme_font_size_override("font_size", 20)
	tag.position = Vector2(-DOOR_SIZE.x * 0.5 + 12, -14)
	_door.add_child(tag)
	_door.body_entered.connect(_on_door_body_entered)
	add_child(_door)


func _build_warden() -> void:
	_warden = Area2D.new()
	_warden.position = Vector2(ROOM_B.position.x + ROOM_B.size.x * 0.5, ROOM_B.position.y + 230)
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = WARDEN_SIZE
	shape.shape = rs
	_warden.add_child(shape)
	var vis := ColorRect.new()
	vis.color = WARDEN_COLOR
	vis.size = WARDEN_SIZE
	vis.position = -WARDEN_SIZE * 0.5
	_warden.add_child(vis)
	var tag := Label.new()
	tag.text = "WARDEN"
	tag.add_theme_font_size_override("font_size", 18)
	tag.position = Vector2(-WARDEN_SIZE.x * 0.5, -WARDEN_SIZE.y * 0.5 - 26)
	_warden.add_child(tag)
	_warden.body_entered.connect(_on_warden_body_entered)
	_warden.body_exited.connect(_on_warden_body_exited)
	add_child(_warden)


func _build_hero() -> void:
	_hero = CharacterBody2D.new()
	_hero.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_hero.position = _cs.hero_pos if _cs.has_pos else spawn_point(ROOM_RECT, HERO_SIZE)
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


## A Camera2D parented to the hero so the view tracks them, smoothed for a soft
## follow and limited to the world bounds so it never scrolls past the walls.
## (The world is shorter than the viewport vertically, so it effectively scrolls
## horizontally as you cross from the start room to the far room.)
func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = CAMERA_SMOOTH_SPEED
	_camera.limit_left = int(ROOM_RECT.position.x - WALL_THICK)
	_camera.limit_top = int(ROOM_RECT.position.y - WALL_THICK)
	_camera.limit_right = int(ROOM_B.end.x + WALL_THICK)
	_camera.limit_bottom = int(ROOM_B.end.y + WALL_THICK)
	_hero.add_child(_camera)
	_camera.make_current()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 24)
	_status.position = Vector2(40, 30)
	layer.add_child(_status)

	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 30)
	_prompt.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_prompt.position = Vector2(660, 980)
	_prompt.visible = false
	layer.add_child(_prompt)

	_bag_button = Button.new()
	_bag_button.text = "🎒 Bag (B)"
	_bag_button.add_theme_font_size_override("font_size", 22)
	_bag_button.position = Vector2(1640, 28)
	_bag_button.pressed.connect(func() -> void: _open_bag(false))
	layer.add_child(_bag_button)

	_update_status()


## The loot-bag overlay floats above the world on its own CanvasLayer. Built once
## and reused — open() repopulates it from the live run each time.
func _build_bag() -> void:
	_bag = LootBagOverlay.new()
	_bag.closed.connect(_on_bag_closed)
	add_child(_bag)


func _open_bag(forced: bool) -> void:
	if _bag == null or RunState.run == null:
		return
	_bag_open = true
	if _bag_button:
		_bag_button.disabled = true
	_bag.open(RunState.run, forced)


func _on_bag_closed() -> void:
	_bag_open = false
	if _bag_button:
		_bag_button.disabled = false
	_update_status()


func _update_status() -> void:
	if _status == null or RunState.run == null:
		return
	var run := RunState.run
	var gate := "Warden down — EXIT open" if _cs.warden_defeated else "A Warden guards the exit"
	_status.text = "HP %d/%d    ·    Bag %d/%d    ·    %s    ·    Arrows move · B bag · Esc menu" % [
		run.hp, run.max_hp, run.haul.size(), run.carry_cap, gate]


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


## Walls fencing the two-room world. `left` and `right` are the rooms (same
## y-band); `corridor` bridges left.end.x → right.position.x. Each room is fully
## boxed except where its facing wall opens onto the corridor mouth, and the
## corridor itself is capped top and bottom so you can't leak out of the passage.
## Pure for tests.
static func world_wall_rects(left: Rect2, right: Rect2, corridor: Rect2, thickness: float) -> Array[Rect2]:
	var t := thickness
	var walls: Array[Rect2] = []
	# Left room: full top / bottom / left; right wall split around the mouth.
	walls.append(Rect2(left.position.x - t, left.position.y - t, left.size.x + t * 2.0, t))        # top
	walls.append(Rect2(left.position.x - t, left.end.y, left.size.x + t * 2.0, t))                 # bottom
	walls.append(Rect2(left.position.x - t, left.position.y, t, left.size.y))                      # left
	walls.append(Rect2(left.end.x, left.position.y, t, corridor.position.y - left.position.y))     # right, above mouth
	walls.append(Rect2(left.end.x, corridor.end.y, t, left.end.y - corridor.end.y))                # right, below mouth
	# Corridor: capped top and bottom.
	walls.append(Rect2(corridor.position.x, corridor.position.y - t, corridor.size.x, t))          # corridor top
	walls.append(Rect2(corridor.position.x, corridor.end.y, corridor.size.x, t))                   # corridor bottom
	# Right room: full top / bottom / right; left wall split around the mouth.
	walls.append(Rect2(right.position.x - t, right.position.y - t, right.size.x + t * 2.0, t))      # top
	walls.append(Rect2(right.position.x - t, right.end.y, right.size.x + t * 2.0, t))               # bottom
	walls.append(Rect2(right.end.x, right.position.y, t, right.size.y))                             # right
	walls.append(Rect2(right.position.x - t, right.position.y, t, corridor.position.y - right.position.y))  # left, above mouth
	walls.append(Rect2(right.position.x - t, corridor.end.y, t, right.end.y - corridor.end.y))      # left, below mouth
	return walls
