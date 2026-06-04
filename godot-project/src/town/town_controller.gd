## TownController — the hub between runs (Phase 3, M4).
##
## Zelda-overworld-style hub (utilitarian placeholder UI for now): four doors —
## Home (outfit the loadout + view the binder), Crafter (shard + grade), Shop
## (buy known-instance ingredients + consumables), and Exit (enter the dungeon
## with the current loadout = the stake). Everything that isn't the dungeon lives
## here. Reads the live economy off GameState for the header counters.
##
## Built in code (matches dungeon_map). No run rules of its own.
class_name TownController
extends Control

const HOME := "home"
const CRAFTER := "crafter"
const SHOP := "shop"
const MENU := "main_menu"
const DUNGEON := "dungeon_map"


func _ready() -> void:
	_build_ui()


func _refresh() -> void:
	for c in get_children():
		c.queue_free()
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.11)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var title := TownUi.label("Town", 52, true)
	title.position = Vector2(0, 80)
	title.size = Vector2(1920, 64)
	add_child(title)

	add_child(_header())

	var col := VBoxContainer.new()
	col.position = Vector2(760, 320)
	col.custom_minimum_size = Vector2(400, 0)
	col.add_theme_constant_override("separation", 18)
	add_child(col)

	col.add_child(_door("Home — Loadout & Binder", HOME))
	col.add_child(_door("Crafter — Grade & Shatter", CRAFTER))
	col.add_child(_door("Shop", SHOP))
	col.add_child(_enter_dungeon_button())

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	col.add_child(spacer)

	var back := TownUi.button("← Back to Menu", 400)
	back.pressed.connect(func() -> void: _go(MENU))
	col.add_child(back)

	_maybe_add_debug_tools(col)


## DEBUG (playtest aid): a fresh save has an empty bench, so the town buildings
## have nothing to act on. This grants a craftable starter set — a 青 phonetic
## family, a 氵 radical family, some shards, and a handful of "seen" characters so
## the shop has stock — letting Home/Crafter/Shop be exercised immediately.
## Debug builds only; folds into a dev menu later.
func _maybe_add_debug_tools(col: VBoxContainer) -> void:
	if not OS.is_debug_build():
		return
	var btn := TownUi.button("+ Debug: grant test bench", 400)
	btn.add_theme_color_override("font_color", TownUi.MUTED)
	btn.pressed.connect(func() -> void:
		_sfx()
		_grant_debug_bench()
		_refresh())
	col.add_child(btn)


func _grant_debug_bench() -> void:
	_ensure_economy()
	var db: CharacterDatabase = GameState.character_db
	# A real connected family drawn from the LOADED set (so every character
	# resolves and the craft is valid). Hardcoded families can reference
	# unloaded higher-HSK characters; this can't.
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

	# A little extra bench fodder + seen characters so the shop has stock.
	var extras := db.get_all().slice(0, 8)
	for j in mini(2, extras.size()):
		GameState.inventory.add(CardInstance.create(extras[j].character, EconomyEnums.Rarity.COMMON))
	for cd in extras:
		GameState.binder.record_seen(cd.character)

	GameState.wallet.add(100)
	if GameState._shop != null:
		GameState._shop.restock()  # surface the newly-seen characters in the store


## n loaded characters that share a connection: prefer a radical shared by >= n
## of them, fall back to a tone shared by >= n. Returns their card_ids, or [] if
## the loaded set somehow has neither (shouldn't happen for HSK 2).
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


func _header() -> Label:
	_ensure_economy()
	var shards: int = GameState.wallet.shards
	var seen: int = GameState.binder.seen_count()
	var bench: int = GameState.inventory.size()
	var equipped: int = GameState.loadout.equipped_count()
	var h := TownUi.colored_label(
		"%d shards   ·   %d on the bench   ·   %d/%d equipped   ·   %d characters in binder" % [
			shards, bench, equipped, GameState.loadout.capacity, seen],
		24, TownUi.MUTED)
	h.position = Vector2(0, 170)
	h.size = Vector2(1920, 34)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return h


func _door(text: String, screen: String) -> Button:
	var b := TownUi.button(text, 400)
	b.custom_minimum_size = Vector2(400, 64)
	b.pressed.connect(func() -> void: _go(screen))
	return b


func _enter_dungeon_button() -> Button:
	var b := TownUi.button("▶  Enter Dungeon", 400)
	b.custom_minimum_size = Vector2(400, 64)
	b.add_theme_color_override("font_color", TownUi.GOOD)
	b.pressed.connect(func() -> void:
		_sfx()
		RunState.begin_run()  # snapshots the current loadout as the stake
		SignalBus.screen_transition_requested.emit(DUNGEON))
	return b


func _go(screen: String) -> void:
	_sfx()
	SignalBus.screen_transition_requested.emit(screen)


func _sfx() -> void:
	AudioManager.play_sfx("button_tap")


func _ensure_economy() -> void:
	# Defensive: the hub may be reached before a save has populated the economy.
	if GameState.inventory == null:
		GameState.load_from_dict({})
