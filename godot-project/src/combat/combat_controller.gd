## CombatController — drives one ATB combat room (Model A vertical slice).
##
## Wires the tested-pure CombatState to the shared AnswerInput, renders a
## code-built battle stage (placeholder rectangles), and routes every first
## answer through GameState.review_scheduler.record_review — the one honest
## FSRS commit. Knowledge is the fuel: a correct answer charges your ATB; a
## full gauge makes the hero hop to the targeted mob and strike; mobs hit
## back on their own timer (and can miss / be blocked). Clear all mobs → a
## RANDOM loot drop. Rectangles are placeholders for real art (M6+).
class_name CombatController
extends Control

const CardDisplayScene := preload("res://scenes/components/card_display.tscn")
# Four answer slots. We tap them now (not swipe), so the direction is just an
# internal id mapping to AnswerInput's choices — no arrow glyphs are shown.
const DIRECTIONS: Array[String] = ["up", "down", "left", "right"]

# --- M1 placeholder tuning ---
const PLAYER_HP := 30
const ATB_PER_CORRECT := 0.34
const ATTACK_DAMAGE := 3
const HERO_ACCURACY := 0.9       # correct answers almost always land; cards → 1.0
const HERO_BLOCK := 0.25         # chance to block an incoming mob hit; cards raise
const MOB_ACCURACY := 0.8        # mobs miss ~20%; cards can lower further
const MAX_MOBS := 3
const FEEDBACK_DELAY := 0.5

# --- stage layout ---
const MOB_SIZE := Vector2(96, 130)
const HERO_SIZE := Vector2(150, 200)            # foreground hero reads bigger
const HERO_SLOT := Vector2(405, 690)            # bottom-center of the left-half diorama
const MOB_COLOR := Color(0.58, 0.30, 0.36)
const HERO_COLOR := Color(0.30, 0.46, 0.62)

# Screen splits in half vertically: LEFT = battle diorama (3/4 view — mobs in
# the back/upper, hero in the foreground); RIGHT = card (top) over answers.
const SCREEN_CENTER_X := 960
const RIGHT_CENTER_X := 1440
const CARD_POS := Vector2(1175, 150)
const CARD_SIZE := Vector2(530, 350)
# Answers stack vertically (tap, not swipe) so long option text has room.
const ANSWER_BTN := Vector2(520, 74)
const ANSWER_START := Vector2(1180, 556)
const ANSWER_GAP := 16
# Hero readout docks bottom-left, beneath the foreground hero.
const INFO_PANEL_POS := Vector2(28, 828)
const INFO_PANEL_SIZE := Vector2(348, 224)

var _answer_generator: AnswerGenerator
var _answer_input: AnswerInput
var _rng: RandomNumberGenerator
var _combat: CombatState

# Dungeon context (null when launched standalone / from the debug button).
# When present, HP is seeded from and written back to the run, the card queue
# is depth-biased, and the result routes back to the map / into a debrief
# rather than showing the in-scene banner.
var _run: DungeonRun = null
var _room: RoomNode = null

var _card_queue: Array[String] = []
var _queue_index: int = 0
var _busy: bool = false
var _finished: bool = false
var _answered: int = 0   # answer tally reported back to the run
var _correct: int = 0

# stage nodes
var _battlefield: Control
var _hero_view: Control
var _hero_body: ColorRect
var _hero_hp_bar: ProgressBar
var _hero_origin: Vector2
var _mob_views: Array[Button] = []
var _mob_bodies: Array[ColorRect] = []
var _mob_hp_bars: Array[ProgressBar] = []
var _mob_markers: Array[Label] = []
var _mob_origins: Array[Vector2] = []

# center play area + hero info panel
var _player_atb_bar: ProgressBar
var _card_display: CardDisplay
var _challenge_label: Label
var _answer_buttons: Dictionary = {}
var _result_panel: Panel
var _result_label: Label


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_answer_generator = AnswerGenerator.new(GameState.character_db)
	_answer_input = AnswerInput.new()
	add_child(_answer_input)
	_answer_input.setup(_answer_generator, null, null)
	_answer_input.answered.connect(_on_answered)

	# Pick up the active dungeon run, if any. Without one this is a standalone
	# fight (debug / tests) with a fresh full-HP pool and a flat card draw.
	if RunState.has_active_run():
		_run = RunState.run
		_room = RunState.current_room

	_build_stage()
	_build_play_area()
	_build_info_panel()
	_card_queue = _build_card_queue()
	var max_hp := _run.max_hp if _run != null else PLAYER_HP
	_combat = CombatState.create(max_hp, _build_mobs(), ATB_PER_CORRECT, ATTACK_DAMAGE, HERO_ACCURACY, HERO_BLOCK)
	if _run != null:
		# Carry the run's current HP into the room (resets to full only per run).
		_combat.player_hp = clampi(_run.hp, 1, _combat.player_max_hp)
	_build_combatants()
	if _card_queue.is_empty() or _combat.current_mob() == null:
		_show_result("No cards / mobs available to fight.")
		return
	_refresh_status()
	_present_next()
	set_process(true)


func _process(delta: float) -> void:
	if _finished or _combat == null:
		return
	for ev in _combat.tick(delta):  # mob gauges fill; ready mobs resolve an attack
		_animate_mob_attack(ev)
	_refresh_status()
	if _combat.is_over():
		_finish()


# -- setup -------------------------------------------------------------------

## Encounters field 1–3 ordinary mobs; an elite is a single tanky mob and the
## boss is tankier still (a Model-A stub until M6's cloze gauntlet replaces it).
## The honest answer→ATB loop is identical across all three — only HP/attack
## scale, so fight length emerges from the bars (no special-cased combat code).
func _build_mobs() -> Array[CombatMob]:
	if _room != null and _room.type == DungeonEnums.RoomType.ELITE:
		return [CombatMob.create("Warden", _rng.randi_range(14, 18), _rng.randi_range(3, 5),
			_rng.randf_range(0.035, 0.05), MOB_ACCURACY)]
	if _room != null and _room.type == DungeonEnums.RoomType.BOSS:
		return [CombatMob.create("Boss", _rng.randi_range(22, 28), _rng.randi_range(4, 6),
			_rng.randf_range(0.03, 0.045), MOB_ACCURACY)]
	var mobs: Array[CombatMob] = []
	for i in _rng.randi_range(1, MAX_MOBS):
		var hp := _rng.randi_range(4, 7)
		var atk := _rng.randi_range(2, 4)
		var rate := _rng.randf_range(0.03, 0.055)  # ~18–33s per strike
		mobs.append(CombatMob.create("Mob %d" % (i + 1), hp, atk, rate, MOB_ACCURACY))
	return mobs


## Build the prompt queue. In a dungeon room the draw is depth-biased (deeper
## rooms dredge up lower-stability cards — the locked depth-biases-the-draw
## rule); standalone falls back to a flat due+new pick. Either way prompts are
## due reviews (knowledge), NOT the mobs and NOT the loot.
func _build_card_queue() -> Array[String]:
	if _run != null and _room != null:
		var now := Time.get_unix_time_from_system()
		var ids := DepthDraw.draw(GameState.review_scheduler, now, _room.depth, 50)
		if not ids.is_empty():
			return ids
	return _pick_card_ids(50)


## Prompts are due reviews (knowledge) — NOT the mobs and NOT the loot.
func _pick_card_ids(n: int) -> Array[String]:
	var now := Time.get_unix_time_from_system()
	var ids: Array[String] = []
	for cs in GameState.review_scheduler.get_due_cards(now):
		if cs.card_id not in ids:
			ids.append(cs.card_id)
	for nid in GameState.review_scheduler.get_new_card_ids():
		if nid not in ids:
			ids.append(nid)
	if ids.is_empty():
		for cd in GameState.character_db.get_all():
			ids.append(cd.get_card_id())
	ids.shuffle()
	return ids.slice(0, mini(n, ids.size()))


# -- presentation ------------------------------------------------------------

func _present_next() -> void:
	if _finished:
		return
	var card_id := _next_card_id()
	var card_data: CharacterData = GameState.character_db.get_character(card_id)
	if card_data == null:
		return
	var challenge_type := GameState.review_scheduler.select_challenge_type(card_id)
	var now := Time.get_unix_time_from_system()
	var rarity: SrsEnums.LootRarity = GameState.review_scheduler.get_loot_rarity(card_id, challenge_type, now)
	_busy = false
	_answer_input.present(card_data, challenge_type, rarity, true)
	_populate_answers()


func _next_card_id() -> String:
	if _card_queue.is_empty():
		return ""
	var id := _card_queue[_queue_index % _card_queue.size()]
	_queue_index += 1
	return id


func _populate_answers() -> void:
	var answers := _answer_input.get_current_answers()
	_challenge_label.text = _prompt_for(answers.get("challenge_type", ""))
	for dir in DIRECTIONS:
		var btn: Button = _answer_buttons[dir]
		btn.text = answers.get(dir, "")
		btn.disabled = false


func _prompt_for(ct: String) -> String:
	match ct:
		"meaning": return "What does this mean?"
		"character": return "Which character?"
		"pinyin": return "What is the pinyin?"
		"tone": return "What tone?"
	return ""


func _on_direction(direction: String) -> void:
	if _busy or _finished or not _answer_input.is_active():
		return
	_answer_input.submit_answer(direction)


# -- resolution (the honest commit lives here) -------------------------------

func _on_answered(card_id: String, challenge_type: String, correct: bool, rating: int) -> void:
	if _finished:
		return
	# THE honest FSRS commit — every first attempt, win or lose.
	var now := Time.get_unix_time_from_system()
	GameState.review_scheduler.record_review(card_id, challenge_type, rating, now)
	if correct:
		AudioManager.play_correct()
	else:
		AudioManager.play_wrong()

	_answered += 1
	if correct:
		_correct += 1

	_combat.answer(correct)                       # correct charges the ATB gauge
	if _combat.player_attack_ready():
		var res := _combat.player_attack()        # full gauge → hop in and strike
		if not res.is_empty():
			_animate_hero_attack(res)

	_busy = true
	for dir in DIRECTIONS:
		_answer_buttons[dir].disabled = true
	_refresh_status()
	get_tree().create_timer(FEEDBACK_DELAY).timeout.connect(_after_answer_beat)


func _after_answer_beat() -> void:
	if _finished:
		return
	if _combat.is_over():
		_finish()
	else:
		_present_next()


func _on_mob_tapped(index: int) -> void:
	if _finished:
		return
	_combat.set_target(index)
	_refresh_status()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	set_process(false)
	for dir in DIRECTIONS:
		if _answer_buttons.has(dir):
			_answer_buttons[dir].disabled = true
	if _run != null:
		_finish_run_room()
	elif _combat.outcome() == CombatState.Outcome.LOST:
		_show_result("You died. Haul lost.")
	else:
		var loot := _roll_loot()
		_show_result("Victory!\nLoot (%d): %s" % [loot.size(), ", ".join(loot) if not loot.is_empty() else "—"])


## Report this room's result into the active run, then route on: a cleared
## room returns to the map (pick the next branch / extract gate); death ends
## the run in a debrief. The run decides win/loss from the surviving HP.
func _finish_run_room() -> void:
	var won := _combat.outcome() == CombatState.Outcome.WON
	# Keep this explicitly Array[String]: an inline `... if won else []` infers
	# the var as Array[String] but feeds it an *untyped* [] on a loss, which
	# fails the runtime type check the moment you die in a room.
	var loot: Array[String] = []
	if won:
		loot = _roll_loot()
	_run.apply_room_result(_combat.player_hp, loot, _answered, _correct)
	if _run.is_over():  # HP hit 0 → died → haul forfeit
		_show_result("You died. Haul lost.")
		_after_run_beat(1.6, "results", true)
	else:
		_run.map.mark_current_cleared()
		var banner := "Victory!\nLoot (%d): %s" % [loot.size(), ", ".join(loot) if not loot.is_empty() else "—"]
		_show_result(banner)
		_after_run_beat(1.2, "dungeon_map", false)


## Hold the result banner for `delay` seconds, then transition. `end_run`
## stamps the debrief into GameState so ResultsScreen can read it on _ready.
func _after_run_beat(delay: float, screen: String, end_run: bool) -> void:
	var go := func() -> void:
		if end_run:
			GameState.end_run(_run.to_summary())  # stamp the debrief first…
			RunState.clear_run()                  # …then drop the finished run
		SignalBus.screen_transition_requested.emit(screen)
	get_tree().create_timer(delay).timeout.connect(go)


## Loot is a RANDOM drop on victory — decoupled from the cards you answered.
## Returns card ids (== character) so the haul stores real ids; instances and
## rarity rolls arrive in M3 (per D7 this is where RarityRoll will hook in).
func _roll_loot() -> Array[String]:
	var pool: Array[String] = []
	for cd in GameState.character_db.get_all():
		pool.append(cd.get_card_id())
	pool.shuffle()
	return pool.slice(0, mini(_rng.randi_range(1, 3), pool.size()))


# -- animations --------------------------------------------------------------

func _animate_hero_attack(res: Dictionary) -> void:
	var idx: int = res.get("mob_index", -1)
	if idx < 0 or idx >= _mob_views.size():
		return
	# Stop just short of the mob, on the hero-facing (foreground) side.
	var to_hero := (_hero_origin - _mob_origins[idx]).normalized()
	var strike_pos := _mob_origins[idx] + to_hero * (MOB_SIZE.x * 0.85 + 24)
	var t := _hero_view.create_tween()
	t.tween_property(_hero_view, "position", strike_pos, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(_hero_strike.bind(res))
	t.tween_property(_hero_view, "position", _hero_origin, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


func _hero_strike(res: Dictionary) -> void:
	var idx: int = res.get("mob_index", -1)
	if idx < 0 or idx >= _mob_views.size():
		return
	var anchor := _mob_origins[idx] + Vector2(MOB_SIZE.x * 0.5, -8)
	if int(res.get("outcome", -1)) == CombatState.AttackOutcome.HIT:
		_shake(_mob_views[idx], _mob_origins[idx])
		_flash(_mob_bodies[idx], MOB_COLOR)
		_float_text(anchor, "-%d" % int(res.get("damage", 0)), Color(1.0, 0.55, 0.3), 46)
	else:
		_float_text(anchor, "Miss", Color(0.72, 0.72, 0.72), 34)


func _animate_mob_attack(ev: Dictionary) -> void:
	var idx: int = ev.get("mob_index", -1)
	if idx < 0 or idx >= _mob_views.size():
		return
	var to_hero := (_hero_origin - _mob_origins[idx]).normalized()
	var lunge := _mob_origins[idx] + to_hero * 52  # charge toward the hero
	var t := _mob_views[idx].create_tween()
	t.tween_property(_mob_views[idx], "position", lunge, 0.12).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(_mob_strike.bind(ev))
	t.tween_property(_mob_views[idx], "position", _mob_origins[idx], 0.14)


func _mob_strike(ev: Dictionary) -> void:
	var anchor := _hero_origin + Vector2(HERO_SIZE.x * 0.5, -8)
	match int(ev.get("outcome", -1)):
		CombatState.AttackOutcome.HIT:
			_shake(_hero_view, _hero_origin)
			_flash(_hero_body, HERO_COLOR)
			_float_text(anchor, "-%d" % int(ev.get("damage", 0)), Color(1.0, 0.3, 0.3), 42)
		CombatState.AttackOutcome.BLOCKED:
			_float_text(anchor, "Block", Color(0.4, 0.7, 1.0), 34)
		_:
			_float_text(anchor, "Miss", Color(0.72, 0.72, 0.72), 34)


func _shake(node: Control, origin: Vector2) -> void:
	var t := node.create_tween()
	t.tween_property(node, "position", origin + Vector2(12, 0), 0.04)
	t.tween_property(node, "position", origin - Vector2(10, 0), 0.04)
	t.tween_property(node, "position", origin + Vector2(6, 0), 0.04)
	t.tween_property(node, "position", origin, 0.04)


func _flash(rect: ColorRect, base: Color) -> void:
	rect.color = Color(1, 0.25, 0.25)
	rect.create_tween().tween_property(rect, "color", base, 0.35)


func _float_text(pos: Vector2, text: String, color: Color, font_size: int) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.z_index = 10
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.position = pos
	_battlefield.add_child(lbl)
	var t := lbl.create_tween()
	t.set_parallel(true)
	t.tween_property(lbl, "position", pos + Vector2(0, -70), 0.7).set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "modulate:a", 0.0, 0.7)
	t.finished.connect(lbl.queue_free)


# -- UI build ----------------------------------------------------------------

func _build_stage() -> void:
	_battlefield = Control.new()
	_battlefield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_battlefield.mouse_filter = Control.MOUSE_FILTER_IGNORE  # children still get clicks
	add_child(_battlefield)


func _build_combatants() -> void:
	var slots := [Vector2(170, 232), Vector2(360, 312), Vector2(248, 452)]
	for i in _combat.mobs.size():
		var origin: Vector2 = slots[i % slots.size()]
		_mob_origins.append(origin)

		var view := Button.new()
		view.flat = true
		view.position = origin
		view.size = MOB_SIZE
		view.pressed.connect(_on_mob_tapped.bind(i))
		_battlefield.add_child(view)

		var body := ColorRect.new()
		body.color = MOB_COLOR
		body.size = MOB_SIZE
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		view.add_child(body)

		var hp := _make_bar(MOB_SIZE.x, 14, Color(0.9, 0.3, 0.35))
		hp.position = Vector2(0, -22)
		view.add_child(hp)

		var marker := Label.new()
		marker.text = "▼"
		marker.add_theme_font_size_override("font_size", 24)
		marker.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		marker.position = Vector2(MOB_SIZE.x * 0.5 - 8, -52)
		marker.visible = false
		view.add_child(marker)

		_mob_views.append(view)
		_mob_bodies.append(body)
		_mob_hp_bars.append(hp)
		_mob_markers.append(marker)

	_hero_origin = HERO_SLOT
	_hero_view = Control.new()
	_hero_view.position = HERO_SLOT
	_hero_view.size = HERO_SIZE
	_battlefield.add_child(_hero_view)

	_hero_body = ColorRect.new()
	_hero_body.color = HERO_COLOR
	_hero_body.size = HERO_SIZE
	_hero_view.add_child(_hero_body)

	# Hero HP now lives in the lower-right info panel (see _build_info_panel).

	var hero_label := Label.new()
	hero_label.text = "HERO"
	hero_label.add_theme_font_size_override("font_size", 16)
	hero_label.position = Vector2(0, HERO_SIZE.y + 4)
	_hero_view.add_child(hero_label)


## Right half of the screen: prompt header + card on top, the answer choices
## stacked vertically below (roomy tap targets for long option text).
func _build_play_area() -> void:
	# Prompt header, centered over the right half above the card.
	_challenge_label = _label("")
	_challenge_label.add_theme_font_size_override("font_size", 30)
	_challenge_label.position = Vector2(RIGHT_CENTER_X - 320, 78)
	_challenge_label.size = Vector2(640, 44)
	_challenge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_challenge_label)

	# Card — top of the right half.
	_card_display = CardDisplayScene.instantiate()
	_card_display.position = CARD_POS
	_card_display.size = CARD_SIZE
	_card_display.custom_minimum_size = CARD_SIZE
	_card_display.clip_contents = true  # belt-and-suspenders against overflow
	add_child(_card_display)
	_answer_input.card_display = _card_display

	# Answers — stacked vertically in the bottom of the right half.
	var col := VBoxContainer.new()
	col.position = ANSWER_START
	col.custom_minimum_size = Vector2(ANSWER_BTN.x, 0)
	col.add_theme_constant_override("separation", ANSWER_GAP)
	add_child(col)
	for dir in DIRECTIONS:
		var btn := Button.new()
		btn.custom_minimum_size = ANSWER_BTN
		btn.clip_text = true
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_direction.bind(dir))
		col.add_child(btn)
		_answer_buttons[dir] = btn

	# Victory / defeat banner — centered overlay so loot never clips off-screen.
	_result_panel = Panel.new()
	_result_panel.position = Vector2(SCREEN_CENTER_X - 460, 412)
	_result_panel.size = Vector2(920, 256)
	var rsb := StyleBoxFlat.new()
	rsb.bg_color = Color(0.08, 0.07, 0.10, 0.94)
	rsb.set_corner_radius_all(14)
	rsb.set_border_width_all(2)
	rsb.border_color = Color(0.5, 0.45, 0.3)
	_result_panel.add_theme_stylebox_override("panel", rsb)
	_result_panel.visible = false
	add_child(_result_panel)

	_result_label = _label("")
	_result_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_label.add_theme_font_size_override("font_size", 36)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_panel.add_child(_result_label)


## Hero readout — HP + ATB gauge — docked lower-right, on the hero's side.
func _build_info_panel() -> void:
	var panel := Panel.new()
	panel.position = INFO_PANEL_POS
	panel.size = INFO_PANEL_SIZE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.13, 0.92)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(2)
	sb.border_color = HERO_COLOR
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.position = Vector2(22, 18)
	vb.custom_minimum_size = Vector2(INFO_PANEL_SIZE.x - 44, 0)
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var title := _label("HERO")
	title.add_theme_font_size_override("font_size", 24)
	vb.add_child(title)

	vb.add_child(_label("HP"))
	_hero_hp_bar = _make_bar(INFO_PANEL_SIZE.x - 44, 24, Color(0.4, 0.8, 0.5))
	vb.add_child(_hero_hp_bar)

	vb.add_child(_label("ATB — answer right to charge, then strike"))
	_player_atb_bar = _make_bar(INFO_PANEL_SIZE.x - 44, 24, Color(0.35, 0.7, 1.0))
	vb.add_child(_player_atb_bar)


func _refresh_status() -> void:
	if _hero_hp_bar:
		_hero_hp_bar.max_value = _combat.player_max_hp
		_hero_hp_bar.value = _combat.player_hp
	if _player_atb_bar:
		_player_atb_bar.value = _combat.player_atb
	for i in _mob_views.size():
		var mob: CombatMob = _combat.mobs[i]
		_mob_hp_bars[i].max_value = mob.max_hp
		_mob_hp_bars[i].value = mob.hp
		var is_target := i == _combat.current_target_index() and mob.is_alive()
		_mob_markers[i].visible = is_target
		if not mob.is_alive():
			_mob_bodies[i].color = Color(0.22, 0.22, 0.22)
			_mob_hp_bars[i].visible = false
			_mob_views[i].disabled = true


func _make_bar(width: float, height: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.size = Vector2(width, height)
	bar.custom_minimum_size = Vector2(width, height)
	bar.max_value = 1.0
	bar.value = 1.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.12, 0.12, 0.85)
	bar.add_theme_stylebox_override("background", bg)
	return bar


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return l


func _show_result(text: String) -> void:
	for dir in DIRECTIONS:
		if _answer_buttons.has(dir):
			_answer_buttons[dir].disabled = true
	if _result_label:
		_result_label.text = text
	if _result_panel:
		_result_panel.visible = true
