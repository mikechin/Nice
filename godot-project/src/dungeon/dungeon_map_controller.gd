## DungeonMapController — the run-map screen (Phase 3, M2 + M3).
##
## Drives traversal of the fixed RunMap: stand on a room, fight it (launch the
## combat scene), come back, pick the next branch, hit an extract gate and
## choose leave-or-push. It owns no run rules — RunState.run (a DungeonRun) is
## the source of truth; this screen reads it, renders the current decision, and
## launches combat / routes to the debrief.
##
## Flow per room kind:
##   fightable + uncleared → "Enter" → combat scene (combat marks it cleared)
##   fightable + cleared   → branch choices (move the cursor forward)
##   extract gate          → Extract (→ triage if over cap) or Push deeper
##   boss cleared          → run complete → extract → results
##
## At extract, the carry cap bites (M3): if the haul exceeds the cap the player
## triages — keep the best N, shatter the rest into shards. Banking the kept
## instances (→ bench + binder) and crediting shards (→ wallet) goes through
## GameState.bank_haul. Death never reaches here — the haul is forfeit in combat.
##
## Placeholder UI built in code (matches combat.tscn's approach) — real
## Zelda-style map art is later. Self-starting: if there's no active run (e.g.
## entered straight from the debug button) it begins one.
class_name DungeonMapController
extends Control

const HEADER_POS := Vector2(0, 70)
const PANEL_POS := Vector2(660, 280)
const PANEL_SIZE := Vector2(600, 520)

var _header: Label
var _subhead: Label
var _actions: VBoxContainer

# Triage state (only live while the triage list is on screen).
var _triage_rows: Array = []        # [{ "ci": CardInstance, "btn": CheckBox }]
var _triage_status: Label
var _confirm_btn: Button


func _ready() -> void:
	if not RunState.has_active_run():
		RunState.begin_run()
	_build_ui()
	_render()


func _build_ui() -> void:
	var title := _label("Dungeon", 40)
	title.position = HEADER_POS
	title.size = Vector2(1920, 56)
	add_child(title)

	_header = _label("", 26)
	_header.position = Vector2(0, 140)
	_header.size = Vector2(1920, 40)
	add_child(_header)

	_subhead = _label("", 22)
	_subhead.position = Vector2(0, 184)
	_subhead.size = Vector2(1920, 36)
	add_child(_subhead)

	var panel := Panel.new()
	panel.position = PANEL_POS
	panel.size = PANEL_SIZE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.13, 0.94)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.4, 0.5, 0.62)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	_actions = VBoxContainer.new()
	_actions.position = Vector2(40, 36)
	_actions.custom_minimum_size = Vector2(PANEL_SIZE.x - 80, 0)
	_actions.add_theme_constant_override("separation", 14)
	panel.add_child(_actions)

	var quit := Button.new()
	quit.text = "Abandon run → Menu"
	quit.custom_minimum_size = Vector2(280, 48)
	quit.position = Vector2(40, PANEL_POS.y + PANEL_SIZE.y + 24)
	quit.pressed.connect(_on_abandon)
	add_child(quit)


func _render() -> void:
	_triage_rows.clear()
	for c in _actions.get_children():
		c.queue_free()

	var run := RunState.run
	if run == null:
		_go("main_menu")
		return
	var map := run.map
	var cur := map.current()
	if cur == null:
		_go("main_menu")
		return

	_header.text = "HP %d/%d   ·   Depth %d   ·   Haul %d/%d   ·   ⬡ %d" % [
		run.hp, run.max_hp, run.depth, run.haul.size(), run.carry_cap, GameState.wallet.shards]
	_subhead.text = "%s  %s" % [DungeonEnums.room_type_icon(cur.type), cur.label]

	# Boss down → the run is won; head to the extract/triage flow and debrief.
	if cur.is_boss() and cur.cleared:
		_begin_extract()
		return

	if cur.is_extract():
		_render_extract_gate(run)
	elif cur.is_fight() and not cur.cleared:
		_render_enter(cur)
	else:
		_render_choices(map)


func _render_enter(cur: RoomNode) -> void:
	var verb := "Face the %s" % cur.label if cur.type != DungeonEnums.RoomType.ENCOUNTER else "Enter %s" % cur.label
	_add_action("%s  %s" % [DungeonEnums.room_type_icon(cur.type), verb], func() -> void:
		RunState.enter_room(cur)
		_go("combat"))


func _render_choices(map: RunMap) -> void:
	var nexts := map.available_next()
	if nexts.is_empty():
		# Cleared terminal that wasn't the boss — shouldn't happen, but bail safe.
		_add_action("Leave the dungeon", _on_abandon)
		return
	var prompt := "Choose your path:" if nexts.size() > 1 else "Press on:"
	_subhead.text += "      " + prompt
	for n in nexts:
		var idx := n.index
		_add_action("%s  %s   (depth %d)" % [DungeonEnums.room_type_icon(n.type), n.label, n.depth], func() -> void:
			_choose(map, idx))


func _render_extract_gate(run: DungeonRun) -> void:
	var carry := "carry %d/%d" % [run.haul.size(), run.carry_cap]
	if run.needs_triage():
		carry += " — triage"
	_add_action("⏏  Extract now (%s)" % carry, _begin_extract)
	for n in run.map.available_next():
		var idx := n.index
		_add_action("⤓  Push deeper → %s (depth %d)" % [n.label, n.depth], func() -> void:
			run.map.mark_current_cleared()
			_choose(run.map, idx))


# -- extract + triage --------------------------------------------------------

## Extract: if the haul fits the cap, bank it straight away; otherwise drop into
## the triage list so the player chooses what comes home.
func _begin_extract() -> void:
	if RunState.run.needs_triage():
		_render_triage()
	else:
		_do_extract([])


## Resolve the run as extracted with the chosen keep-set (empty → auto-keep the
## best N), credit bench/binder/wallet, stamp the debrief, and route to results.
func _do_extract(keep: Array) -> void:
	var run := RunState.run
	run.extract(keep)
	GameState.bank_haul(run.banked_haul(), run.shattered_haul())
	GameState.resolve_stake(true)  # extracted alive — the staked kit comes home
	GameState.end_run(run.to_summary())
	RunState.clear_run()
	_go("results")


## The carry-cap triage list: every carried instance, best-first, the top `cap`
## pre-selected. Toggle to choose; unselected instances shatter into shards.
func _render_triage() -> void:
	for c in _actions.get_children():
		c.queue_free()
	_triage_rows.clear()

	var run := RunState.run
	_subhead.text = "Over carry cap — keep your best %d, shatter the rest" % run.carry_cap

	_triage_status = _label("", 22)
	_actions.add_child(_triage_status)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(PANEL_SIZE.x - 80, 340)
	_actions.add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(PANEL_SIZE.x - 110, 0)
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	var sorted := run.haul.duplicate()
	sorted.sort_custom(func(a: CardInstance, b: CardInstance) -> bool:
		return a.sort_key() > b.sort_key())
	for i in sorted.size():
		var ci: CardInstance = sorted[i]
		var cb := CheckBox.new()
		cb.button_pressed = i < run.carry_cap        # pre-select the best N
		cb.text = "%s   (+%d shards if dropped)" % [ci.display_label(), ci.shard_value()]
		cb.add_theme_font_size_override("font_size", 20)
		cb.add_theme_color_override("font_color", EconomyEnums.rarity_color(ci.rarity))
		cb.toggled.connect(func(_pressed: bool) -> void: _update_triage_status())
		list.add_child(cb)
		_triage_rows.append({ "ci": ci, "btn": cb })

	_confirm_btn = Button.new()
	_confirm_btn.text = "Extract selected"
	_confirm_btn.custom_minimum_size = Vector2(PANEL_SIZE.x - 80, 54)
	_confirm_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_tap")
		_confirm_triage())
	_actions.add_child(_confirm_btn)

	var back := Button.new()
	back.text = "← Back"
	back.custom_minimum_size = Vector2(PANEL_SIZE.x - 80, 44)
	back.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_tap")
		_render())
	_actions.add_child(back)

	_update_triage_status()


func _update_triage_status() -> void:
	var run := RunState.run
	var kept := 0
	var shards := 0
	for row in _triage_rows:
		if row["btn"].button_pressed:
			kept += 1
		else:
			shards += row["ci"].shard_value()
	var over := kept > run.carry_cap
	_triage_status.text = "Keep %d/%d   ·   shatter %d → +%d shards%s" % [
		kept, run.carry_cap, _triage_rows.size() - kept, shards,
		"   (over cap!)" if over else ""]
	if _confirm_btn:
		_confirm_btn.disabled = over


func _confirm_triage() -> void:
	var keep: Array = []
	for row in _triage_rows:
		if row["btn"].button_pressed:
			keep.append(row["ci"])
	_do_extract(keep)


# -- actions -----------------------------------------------------------------

func _choose(map: RunMap, idx: int) -> void:
	# (_add_action already played the tap sound for this press.)
	if map.move_to(idx):
		RunState.enter_room(map.current())
	_render()


func _on_abandon() -> void:
	AudioManager.play_sfx("button_tap")
	RunState.clear_run()
	_go("main_menu")


func _go(screen: String) -> void:
	SignalBus.screen_transition_requested.emit(screen)


# -- helpers -----------------------------------------------------------------

func _add_action(text: String, on_press: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(PANEL_SIZE.x - 80, 64)
	btn.clip_text = true
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_tap")
		on_press.call())
	_actions.add_child(btn)
	return btn


func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l
