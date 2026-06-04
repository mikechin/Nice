## TownWorld — the spatial between-runs hub (Phase 3, M4 → loop-closure 2026-06-04).
##
## The walkable town, built in the same idiom as the dungeon CrawlRoom: a top-down
## Node2D space wider than the 1920×1080 frame, with a hero-following Camera2D that
## scrolls as you cross it. Instead of fighting, you visit buildings:
##   - Home      — outfit the loadout + view the binder
##   - Crafter   — grade & shatter
##   - Shop      — buy known-instance ingredients + consumables
##   - Dungeon   — the gate; walk up + Enter to begin a run (snapshots the loadout
##                 as the stake) and drop into the spatial crawl.
##
## Each building is a solid structure with a glowing **door zone** in front; step
## onto a zone and a prompt appears — press Enter to go in. The interiors are the
## existing M4 button screens (home/crafter/shop), reached by SignalBus transition;
## their "← Town" buttons return here. The town owns no run state — it's the hub
## the loop returns to (results → town). Input via the built-in ui_* actions so it's
## keyboard + gamepad ready, matching CrawlRoom.
class_name TownWorld
extends Node2D

const HERO_SPEED := 430.0
const HERO_SIZE := Vector2(74, 98)
const HERO_COLOR := Color(0.30, 0.46, 0.62)

# One wide plaza — far wider than the 1920 viewport so the camera scrolls
# horizontally as you walk from Home (left) to the Dungeon gate (right). Shorter
# than the frame vertically, so (like the crawl) a void backdrop fills the gap.
const WORLD := Rect2(200, 200, 3120, 700)
const WALL_THICK := 26.0
const GROUND_COLOR := Color(0.13, 0.145, 0.12)      # warmer/greener than the dungeon floor
const PATH_COLOR := Color(0.17, 0.165, 0.14)        # a packed-earth path along the plaza
const VOID_COLOR := Color(0.04, 0.045, 0.038)       # backdrop beyond the walls
const WALL_COLOR := Color(0.30, 0.31, 0.34)
const CAMERA_SMOOTH_SPEED := 7.0

const BUILDING_SIZE := Vector2(320, 280)
const DOOR_ZONE := Vector2(240, 130)                # the approach strip in front of a door
const PATH_HEIGHT := 200.0

# Door-zone accent colors (the lit doorway), one per destination.
const HOME_COLOR := Color(0.34, 0.47, 0.62)
const CRAFTER_COLOR := Color(0.62, 0.45, 0.30)
const SHOP_COLOR := Color(0.36, 0.54, 0.38)
const DUNGEON_COLOR := Color(0.60, 0.26, 0.30)
const ZONE_COLOR := Color(1.0, 0.85, 0.35, 0.16)    # faint glow on the approach strip

## The door the hero last left town by — a destination id ("home"/"crafter"/
## "shop"/"dungeon") or "" for the town entrance. Static so it survives the scene
## swap into a building/dungeon and back: when town reloads, the hero steps out at
## this door instead of restarting at the entrance. "" again on a trip to the menu.
static var _return_spawn_id: String = ""

var _hero: CharacterBody2D
var _camera: Camera2D
var _header: Label
var _prompt: Label
var _active: Dictionary = {}            # the door zone the hero is standing in, {} if none
var _busy: bool = false                 # true while a transition is in flight


func _ready() -> void:
	_ensure_economy()
	_build_backdrop()
	_build_ground()
	_build_walls()
	for desc in _destinations():
		_build_destination(desc)
	_build_hero()
	_build_camera()
	_build_hud()


func _physics_process(delta: float) -> void:
	if _busy or _hero == null:
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_hero.velocity = dir * HERO_SPEED
	_hero.move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("ui_cancel"):
		_return_spawn_id = ""            # arriving from the menu → spawn at the entrance
		SignalBus.screen_transition_requested.emit("main_menu")
		return
	if event.is_action_pressed("ui_accept") and not _active.is_empty():
		_enter(_active)
		return
	# DEBUG (playtest aid): a fresh save has an empty bench, so the buildings have
	# nothing to act on. G grants a craftable starter set. Debug builds only.
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_G:
		_grant_debug_bench()
		_update_header()


# -- destinations ------------------------------------------------------------

## The four things you can walk up to. `screen` is the navigator key; the dungeon
## gate is flagged so Enter begins a run instead of a plain transition. Laid out
## left→right across the plaza so the camera reveals them as you cross.
func _destinations() -> Array[Dictionary]:
	var mid_y := WORLD.position.y + 150.0
	return [
		{"id": "home", "label": "Home", "sign": "Loadout & Binder", "screen": "home",
			"color": HOME_COLOR, "cx": WORLD.position.x + 480.0, "y": mid_y, "dungeon": false},
		{"id": "crafter", "label": "Crafter", "sign": "Grade & Shatter", "screen": "crafter",
			"color": CRAFTER_COLOR, "cx": WORLD.position.x + 1180.0, "y": mid_y, "dungeon": false},
		{"id": "shop", "label": "Shop", "sign": "Buy ingredients", "screen": "shop",
			"color": SHOP_COLOR, "cx": WORLD.position.x + 1880.0, "y": mid_y, "dungeon": false},
		{"id": "dungeon", "label": "Dungeon", "sign": "Enter ▶ stake your kit", "screen": "crawl",
			"color": DUNGEON_COLOR, "cx": WORLD.position.x + 2720.0, "y": mid_y, "dungeon": true},
	]


func _enter(desc: Dictionary) -> void:
	_busy = true
	AudioManager.play_sfx("button_tap")
	# Remember this door so we step back out of it on return (from the building, or
	# from the whole dungeon run — the gate id "dungeon" survives results → town).
	_return_spawn_id = String(desc["id"])
	if desc.get("dungeon", false):
		RunState.begin_run()             # snapshots the current loadout as the stake
		SignalBus.screen_transition_requested.emit("crawl")
	else:
		SignalBus.screen_transition_requested.emit(desc["screen"])


# -- contact -----------------------------------------------------------------

func _on_zone_entered(body: Node, desc: Dictionary) -> void:
	if body != _hero:
		return
	_active = desc
	if _prompt:
		_prompt.text = "Enter ▶ %s — %s" % [desc["label"], desc["sign"]]
		_prompt.visible = true


func _on_zone_exited(body: Node, desc: Dictionary) -> void:
	if body != _hero:
		return
	if _active.get("id", "") == desc.get("id", ""):
		_active = {}
		if _prompt:
			_prompt.visible = false


# -- build -------------------------------------------------------------------

## Dark plate behind everything so the area the camera reveals beyond the walls
## (the world is shorter than the viewport) reads as void, not a rendering gap.
func _build_backdrop() -> void:
	var pad := Vector2(900, 900)
	var top_left := WORLD.position - Vector2(WALL_THICK, WALL_THICK) - pad
	var bottom_right := WORLD.end + Vector2(WALL_THICK, WALL_THICK) + pad
	var bd := ColorRect.new()
	bd.color = VOID_COLOR
	bd.position = top_left
	bd.size = bottom_right - top_left
	add_child(bd)


func _build_ground() -> void:
	var g := ColorRect.new()
	g.color = GROUND_COLOR
	g.position = WORLD.position
	g.size = WORLD.size
	add_child(g)
	# A path strip the buildings sit along — purely cosmetic, gives the plaza a spine.
	var path := ColorRect.new()
	path.color = PATH_COLOR
	path.position = Vector2(WORLD.position.x, WORLD.position.y + WORLD.size.y - PATH_HEIGHT - 90.0)
	path.size = Vector2(WORLD.size.x, PATH_HEIGHT)
	add_child(path)


func _build_walls() -> void:
	# Reuse the crawl's tested wall geometry — one boxed room.
	for r in CrawlRoom.wall_rects(WORLD, WALL_THICK):
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


## A building = a solid structure (you can't walk through it) + a lit door-zone
## Area2D on the path in front of it that fires the proximity prompt.
func _build_destination(desc: Dictionary) -> void:
	var structure := _structure_rect(desc)
	_add_structure(structure, desc)

	var zone_rect := door_zone_rect(structure, DOOR_ZONE)
	var zone := Area2D.new()
	zone.position = zone_rect.position + zone_rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = zone_rect.size
	shape.shape = rs
	zone.add_child(shape)
	var glow := ColorRect.new()
	glow.color = ZONE_COLOR
	glow.size = zone_rect.size
	glow.position = -zone_rect.size * 0.5
	zone.add_child(glow)
	zone.body_entered.connect(_on_zone_entered.bind(desc))
	zone.body_exited.connect(_on_zone_exited.bind(desc))
	add_child(zone)


func _add_structure(rect: Rect2, desc: Dictionary) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	body.add_child(shape)

	# Wall slab.
	var wall := ColorRect.new()
	wall.color = Color(0.20, 0.20, 0.24)
	wall.size = rect.size
	wall.position = -rect.size * 0.5
	body.add_child(wall)
	# A colored doorway/roof band so each building reads at a glance.
	var band := ColorRect.new()
	band.color = desc["color"]
	band.size = Vector2(rect.size.x, 64)
	band.position = Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5)
	body.add_child(band)

	var name_lbl := Label.new()
	name_lbl.text = desc["label"]
	name_lbl.add_theme_font_size_override("font_size", 34)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.position = Vector2(-rect.size.x * 0.5 + 16, -rect.size.y * 0.5 + 80)
	body.add_child(name_lbl)
	add_child(body)


func _build_hero() -> void:
	_hero = CharacterBody2D.new()
	_hero.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_hero.position = _spawn_position()
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


func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = CAMERA_SMOOTH_SPEED
	_camera.limit_left = int(WORLD.position.x - WALL_THICK)
	_camera.limit_top = int(WORLD.position.y - WALL_THICK)
	_camera.limit_right = int(WORLD.end.x + WALL_THICK)
	_camera.limit_bottom = int(WORLD.end.y + WALL_THICK)
	_hero.add_child(_camera)
	_camera.make_current()
	_camera.reset_smoothing()            # snap to the spawn door, don't pan in from afar


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var title := Label.new()
	title.text = "Town"
	title.add_theme_font_size_override("font_size", 40)
	title.position = Vector2(40, 24)
	layer.add_child(title)

	_header = Label.new()
	_header.add_theme_font_size_override("font_size", 22)
	_header.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
	_header.position = Vector2(40, 78)
	layer.add_child(_header)
	_update_header()

	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 30)
	_prompt.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_prompt.position = Vector2(560, 940)
	_prompt.size = Vector2(800, 36)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.visible = false
	layer.add_child(_prompt)

	var hint := Label.new()
	var tail := "   ·   G grant bench" if OS.is_debug_build() else ""
	hint.text = "Arrows move   ·   Enter to go in   ·   Esc to menu" + tail
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.55, 0.57, 0.62))
	hint.position = Vector2(40, 1030)
	layer.add_child(hint)


func _update_header() -> void:
	if _header == null:
		return
	var shards: int = GameState.wallet.shards
	var bench: int = GameState.inventory.size()
	var equipped: int = GameState.loadout.equipped_count()
	var seen: int = GameState.binder.seen_count()
	_header.text = "%d shards   ·   %d on the bench   ·   %d/%d equipped   ·   %d in binder" % [
		shards, bench, equipped, GameState.loadout.capacity, seen]


# -- geometry (pure, testable) -----------------------------------------------

func _structure_rect(desc: Dictionary) -> Rect2:
	return Rect2(desc["cx"] - BUILDING_SIZE.x * 0.5, desc["y"], BUILDING_SIZE.x, BUILDING_SIZE.y)


## Where the hero appears on entering the town. Returning from a building (or
## extracting from the dungeon), they step out just below that door — not back at
## the entrance. Falls back to the left entrance when there's no remembered door
## (e.g. arriving from the menu).
func _spawn_position() -> Vector2:
	for desc in _destinations():
		if desc["id"] == _return_spawn_id:
			var zone := door_zone_rect(_structure_rect(desc), DOOR_ZONE)
			# Just below the door zone, on the path — clear of the zone so the
			# "Enter" prompt doesn't immediately re-fire on the door you just used.
			return Vector2(zone.position.x + zone.size.x * 0.5, zone.end.y + HERO_SIZE.y * 0.5 + 8.0)
	return Vector2(WORLD.position.x + 300.0, WORLD.end.y - 150.0)


## The approach strip in front of a building's base: a `zone`-sized rect centered
## on the structure's bottom edge, sitting just below it (where the hero walks up
## to the door). Pure for tests.
static func door_zone_rect(structure: Rect2, zone: Vector2) -> Rect2:
	return Rect2(
		structure.position.x + structure.size.x * 0.5 - zone.x * 0.5,
		structure.end.y,
		zone.x, zone.y)


# -- debug bench -------------------------------------------------------------

## DEBUG (playtest aid): grant a craftable starter set — a real connected family
## drawn from the LOADED database (so every character resolves and the craft is
## valid), some shards, and a handful of "seen" characters so the shop has stock.
## Mirrors the old town_controller debug grant. Debug builds only.
func _grant_debug_bench() -> void:
	_ensure_economy()
	var db: CharacterDatabase = GameState.character_db
	var family := _debug_family(db, 4)
	if family.is_empty():
		push_warning("town: no connected family in the loaded DB to seed")
		return

	# family[0] = rare target to grade; the rest = ingredients.
	var target := GameState.inventory.add(CardInstance.create(family[0], EconomyEnums.Rarity.RARE))
	GameState.binder.record_seen(target.card_id)
	for i in range(1, family.size()):
		var ci := GameState.inventory.add(CardInstance.create(family[i], EconomyEnums.Rarity.COMMON))
		GameState.binder.record_seen(ci.card_id)

	# Extra bench fodder + seen characters so the shop has stock.
	var extras := db.get_all().slice(0, 8)
	for j in mini(2, extras.size()):
		GameState.inventory.add(CardInstance.create(extras[j].character, EconomyEnums.Rarity.COMMON))
	for cd in extras:
		GameState.binder.record_seen(cd.character)

	GameState.wallet.add(100)
	if GameState._shop != null:
		GameState._shop.restock()


## n loaded characters that share a connection: prefer a radical shared by >= n of
## them, fall back to a tone shared by >= n. Returns their card_ids, or [] if the
## loaded set has neither (shouldn't happen for HSK 2).
func _debug_family(db: CharacterDatabase, n: int) -> Array[String]:
	for r in db.get_all_radicals():
		var chars: Array = db.get_by_radical(r)
		if chars.size() >= n:
			return _first_n_chars(chars, n)
	for tone in [1, 2, 3, 4, 0]:
		var by_tone: Array = db.get_by_tone(tone)
		if by_tone.size() >= n:
			return _first_n_chars(by_tone, n)
	return []


func _first_n_chars(chars: Array, n: int) -> Array[String]:
	var ids: Array[String] = []
	for cd in chars:
		ids.append(cd.character)
		if ids.size() >= n:
			break
	return ids


func _ensure_economy() -> void:
	# Defensive: the hub may be reached before a save has populated the economy.
	if GameState.inventory == null:
		GameState.load_from_dict({})
