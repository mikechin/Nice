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
const DAMAGE_SPREAD := 1          # hits roll ATTACK_DAMAGE ± this (2–4) for texture
const CRIT_CHANCE := 0.15         # 15% of landed hits crit (the design-sanctioned RNG)
const CRIT_MULTIPLIER := 2.0      # crits double the rolled damage
const LIMIT_PER_CLUTCH := 0.2     # clutch recalls charge the LIMIT bar by this (< ATB_PER_CORRECT)
const LIMIT_DAMAGE := ATTACK_DAMAGE * 4   # limit break: big flat damage to EVERY mob
const HERO_ACCURACY := 0.9       # correct answers almost always land; cards → 1.0
const HERO_BLOCK := 0.25         # chance to block an incoming mob hit; cards raise
const MOB_ACCURACY := 0.8        # mobs miss ~20%; cards can lower further
const MAX_MOBS := 3
const FEEDBACK_DELAY := 0.5
const MAX_NEW_PER_FIGHT := 3     # teach at most this many first-sight cards per fight

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
# Hero readout docks bottom-left, beneath the foreground hero (taller now to
# hold the LIMIT gauge + unleash button under HP/ATB).
const INFO_PANEL_POS := Vector2(28, 712)
const INFO_PANEL_SIZE := Vector2(348, 340)

var _answer_generator: AnswerGenerator
var _answer_input: AnswerInput
var _rng: RandomNumberGenerator
var _combat: CombatState
# The equipped kit's combat contribution (M5): passive bonuses folded into the
# CombatState below, active riders (burn/heal) fired on each correct answer.
var _mods: CombatMods

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
# Loot-roll context (M3): consecutive-correct streak and whether any clutch
# (ABOUT_TO_FORGET) card was recalled this room — both bias the rarity roll up.
var _streak: int = 0
var _clutch: bool = false
var _current_loot_rarity: SrsEnums.LootRarity = SrsEnums.LootRarity.KNOWN
# DEBUG aid: in a debug build (editor / debug export) mark the correct answer
# with a ★ to speed playtesting. Always false in a release export, so the hint
# never ships; flip to `true` here to force it on regardless.
var _debug_reveal_answer: bool = OS.is_debug_build()

# Scaffolded teaching: a first-sight card is taught (reveal block) before it's
# tested. While the teach beat is up the combat clock pauses (mobs hold) so
# learning isn't punished.
var _paused: bool = false
var _teaching: bool = false
var _teach_revealed: bool = false
var _teach_card_id: String = ""
var _teach_ct: String = ""
var _teach_button: Button

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
var _limit_bar: ProgressBar
var _limit_button: Button
var _kit_label: Label                # compact readout of the staked kit's bonuses (M5)
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
	# The kit you staked turns into combat bonuses (M5). Passive kinds raise the
	# fight's setup stats; active kinds (burn/heal) fire per correct answer below.
	_mods = CombatLoadout.assemble(GameState.loadout, GameState.character_db)
	if _kit_label:
		_kit_label.text = "Kit: " + _mods.summary()
	var base_hp := _run.max_hp if _run != null else PLAYER_HP
	var max_hp := base_hp + _mods.max_hp_i()
	_combat = CombatState.create(
		max_hp, _build_mobs(), ATB_PER_CORRECT,
		ATTACK_DAMAGE + _mods.attack_i(),
		HERO_ACCURACY + _mods.accuracy,
		HERO_BLOCK + _mods.block)
	_combat.damage_spread = DAMAGE_SPREAD
	_combat.crit_chance = clampf(CRIT_CHANCE + _mods.crit, 0.0, 1.0)
	_combat.atb_per_correct = clampf(ATB_PER_CORRECT + _mods.atb, 0.01, 1.0)
	_combat.crit_multiplier = CRIT_MULTIPLIER
	_combat.limit_per_clutch = LIMIT_PER_CLUTCH
	_combat.limit_damage = LIMIT_DAMAGE
	if _run != null:
		# Carry the run's current HP into the room (resets to full only per run).
		_combat.player_hp = clampi(_run.hp, 1, _combat.player_max_hp)
		# LIMIT charge likewise survives encounters within a run (a fresh run /
		# new dungeon instance starts at 0 — see DungeonRun.create).
		_combat.limit = clampf(_run.limit, 0.0, 1.0)
	_build_combatants()
	if _card_queue.is_empty() or _combat.current_mob() == null:
		_show_result("No cards / mobs available to fight.")
		return
	_refresh_status()
	_present_next()
	set_process(true)


func _process(delta: float) -> void:
	if _finished or _combat == null or _paused:
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
		# Ordinary mobs die in 1–2 hits (HP scales off the hero's hit damage),
		# so encounters stay snappy — the wall is the cards, not mob bulk.
		var hp := _rng.randi_range(ATTACK_DAMAGE, ATTACK_DAMAGE * 2)
		var atk := _rng.randi_range(2, 4)
		var rate := _rng.randf_range(0.03, 0.055)  # ~18–33s per strike
		mobs.append(CombatMob.create("Mob %d" % (i + 1), hp, atk, rate, MOB_ACCURACY))
	return mobs


## Build the prompt queue. In a dungeon room the draw is depth-biased (deeper
## rooms dredge up lower-stability cards — the locked depth-biases-the-draw
## rule); standalone falls back to a flat due+new pick. Either way prompts are
## due reviews (knowledge), NOT the mobs and NOT the loot.
func _build_card_queue() -> Array[String]:
	var ids: Array[String] = []
	if _run != null and _room != null:
		var now := Time.get_unix_time_from_system()
		ids = DepthDraw.draw(GameState.review_scheduler, now, _room.depth, 50)
	if ids.is_empty():
		ids = _pick_card_ids(50)
	return _ration_new(ids)


## Cap how many brand-new (teach) cards a single fight introduces so a fresh
## deck isn't a wall of reveal beats — and so the fight stays winnable (taught
## cards cycle back as answerable 2-option recognition that charges the ATB).
func _ration_new(ids: Array[String]) -> Array[String]:
	var out: Array[String] = []
	var new_count := 0
	for id in ids:
		var cs: CardState = GameState.review_scheduler.card_states.get(id)
		if cs == null or cs.is_new():
			if new_count >= MAX_NEW_PER_FIGHT:
				continue
			new_count += 1
		out.append(id)
	return out


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
	_current_loot_rarity = rarity  # remembered so a correct clutch recall can bias loot

	# Scaffold by strength: teach first-sight cards, ease weak ones in with 2
	# options, demand full recall (4) once they're strong.
	match _format_for(card_id, challenge_type):
		ChallengeScaffold.Format.TEACH:
			_present_teach(card_data, challenge_type)
		ChallengeScaffold.Format.RECOGNIZE:
			_present_quiz(card_data, challenge_type, rarity, 2)
		_:
			_present_quiz(card_data, challenge_type, rarity, 4)


func _format_for(card_id: String, challenge_type: String) -> ChallengeScaffold.Format:
	var cs: CardState = GameState.review_scheduler.card_states.get(card_id)
	if cs == null:
		return ChallengeScaffold.Format.TEACH
	var stability: float = cs.get_state_for_type(challenge_type).get("stability", 0.0)
	return ChallengeScaffold.format_for(cs.is_new(), stability)


## A standard quiz: present the card and show `num_options` answer buttons
## (2 = early recognition, 4 = full recall).
func _present_quiz(card_data: CharacterData, challenge_type: String, rarity: SrsEnums.LootRarity, num_options: int) -> void:
	_teaching = false
	_paused = false
	_busy = false
	if _teach_button:
		_teach_button.visible = false
	_answer_input.present(card_data, challenge_type, rarity, true)
	_populate_answers(num_options)


## First-sight teaching: show the card, reveal the answer on tap, then commit an
## honest first review and move on. Mobs hold (clock pauses); no ATB — there is
## no recall to fuel it yet, just learning.
func _present_teach(card_data: CharacterData, challenge_type: String) -> void:
	_teaching = true
	_teach_revealed = false
	_busy = true
	_paused = true
	_teach_card_id = card_data.get_card_id()
	_teach_ct = challenge_type
	_current_loot_rarity = SrsEnums.LootRarity.NEW_CARD
	_card_display.setup_for_challenge(card_data, challenge_type, SrsEnums.LootRarity.NEW_CARD)
	_card_display.show_new_discovery_effect()
	_challenge_label.text = "New character!   " + _prompt_for(challenge_type)
	for dir in DIRECTIONS:
		_answer_buttons[dir].visible = false
	if _limit_button:
		_limit_button.disabled = true   # clock paused — no unleash mid-teach
	_teach_button.text = "Reveal answer"
	_teach_button.disabled = false
	_teach_button.visible = true


func _on_teach_pressed() -> void:
	if not _teaching:
		return
	AudioManager.play_sfx("button_tap")
	if not _teach_revealed:
		_teach_revealed = true
		_card_display.reveal()
		_teach_button.text = "Got it — continue"
	else:
		_commit_teach()


func _commit_teach() -> void:
	_teaching = false
	_paused = false
	if _teach_button:
		_teach_button.visible = false
	# Honest first review: a just-introduced card is weak, so it commits AGAIN
	# (Anki-style) — it returns soon as an easy 2-option recognition.
	var now := Time.get_unix_time_from_system()
	GameState.review_scheduler.record_review(_teach_card_id, _teach_ct, FsrsAlgorithm.Rating.AGAIN, now)
	GameState.binder.record_seen(_teach_card_id)
	get_tree().create_timer(FEEDBACK_DELAY).timeout.connect(_after_answer_beat)


func _next_card_id() -> String:
	if _card_queue.is_empty():
		return ""
	var id := _card_queue[_queue_index % _card_queue.size()]
	_queue_index += 1
	return id


func _populate_answers(num_options: int) -> void:
	var answers := _answer_input.get_current_answers()
	_challenge_label.text = _prompt_for(answers.get("challenge_type", ""))
	var correct_dir: String = answers.get("correct_direction", "")
	var shown := _directions_to_show(correct_dir, num_options)
	for dir in DIRECTIONS:
		var btn: Button = _answer_buttons[dir]
		if dir in shown:
			var label: String = answers.get(dir, "")
			if _debug_reveal_answer and dir == correct_dir and label != "":
				label = "★ " + label
			btn.text = label
			btn.disabled = false
			btn.visible = true
		else:
			btn.visible = false
			btn.disabled = true


## Which answer directions to show: always the correct one, plus random
## distractors up to `count` (2 = recognition, 4 = all = full recall).
func _directions_to_show(correct_dir: String, count: int) -> Array:
	if count >= DIRECTIONS.size() or correct_dir == "":
		return DIRECTIONS.duplicate()
	var others := DIRECTIONS.filter(func(d: String) -> bool: return d != correct_dir)
	others.shuffle()
	var shown: Array = [correct_dir]
	for i in mini(count - 1, others.size()):
		shown.append(others[i])
	return shown


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
	# Encountering a card in a run records it in the permanent binder (factual
	# "seen"), independent of the FSRS ledger and of whether you survive.
	GameState.binder.record_seen(card_id)
	if correct:
		AudioManager.play_correct()
	else:
		AudioManager.play_wrong()

	_answered += 1
	if correct:
		_correct += 1
		_streak += 1
		# A correctly recalled about-to-forget card is the clutch win that
		# weights this room's loot rolls up (RarityRoll).
		if _current_loot_rarity == SrsEnums.LootRarity.ABOUT_TO_FORGET:
			_clutch = true
	else:
		_streak = 0

	# A correct clutch (about-to-forget) recall charges the ATB normally AND feeds
	# the separate LIMIT bar — the clutch payoff (new cards never reach here:
	# they're taught, not answered). Clutch saves bank toward a limit-break burst.
	_combat.answer(correct)                       # correct charges the ATB gauge
	if correct:
		_apply_active_riders()                    # kit burn/heal land on every correct
	if correct and _current_loot_rarity == SrsEnums.LootRarity.ABOUT_TO_FORGET:
		_combat.charge_limit()
	if _combat.player_attack_ready():
		var res := _combat.player_attack()        # full gauge → hop in and strike
		if not res.is_empty():
			_animate_hero_attack(res)

	_busy = true
	for dir in DIRECTIONS:
		_answer_buttons[dir].disabled = true
	_refresh_status()
	get_tree().create_timer(FEEDBACK_DELAY).timeout.connect(_after_answer_beat)


## The active half of the kit (M5): on a correct answer, MEND cards heal the hero
## and BURN cards chip the current target — outside the ATB gauge, so they reward
## accuracy directly. A burn that kills is caught by the over-checks downstream.
func _apply_active_riders() -> void:
	if _mods == null:
		return
	if _mods.heal_i() > 0:
		_combat.heal_player(_mods.heal_i())
	if _mods.burn_i() > 0:
		_combat.strike_target(_mods.burn_i())


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


## Player-triggered limit break: spend the full LIMIT gauge for a screen-wide
## burst. Independent of the ATB / answer flow — fire it whenever it's armed.
## A win is detected by _process (which calls _finish), same as a normal kill.
func _on_limit_pressed() -> void:
	if _finished or _paused or _combat == null or not _combat.limit_ready():
		return
	AudioManager.play_sfx("button_tap")
	var res := _combat.unleash_limit()
	if not res.is_empty():
		_animate_limit_break(res)
	_refresh_status()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	set_process(false)
	for dir in DIRECTIONS:
		if _answer_buttons.has(dir):
			_answer_buttons[dir].disabled = true
	if _teach_button:
		_teach_button.visible = false
	if _limit_button:
		_limit_button.disabled = true
	if _run != null:
		_finish_run_room()
	elif _combat.outcome() == CombatState.Outcome.LOST:
		_show_result("You died. Haul lost.")
	else:
		var loot := _roll_loot()
		_show_result("Victory!\nLoot (%d): %s" % [loot.size(), _loot_label(loot)])


## Report this room's result into the active run, then route on: a cleared
## room returns to the map (pick the next branch / extract gate); death ends
## the run in a debrief. The run decides win/loss from the surviving HP.
func _finish_run_room() -> void:
	var won := _combat.outcome() == CombatState.Outcome.WON
	# Keep this explicitly typed: an inline `... if won else []` infers the var
	# from the _roll_loot() branch but feeds it an *untyped* [] on a loss, which
	# fails the runtime type check the moment you die in a room.
	var loot: Array[CardInstance] = []
	if won:
		loot = _roll_loot()
	# Persist the LIMIT charge into the run so it carries to the next encounter.
	_run.limit = _combat.limit
	_run.apply_room_result(_combat.player_hp, loot, _answered, _correct)
	if _run.is_over():  # HP hit 0 → died → haul forfeit
		_show_result("You died. Haul lost.")
		_after_run_beat(1.6, "results", true)
	else:
		# Route back to whoever launched the fight. The node-map flow tracks
		# cleared rooms on the RunMap; the spatial crawl doesn't (it owns its own
		# warden/door state), so only do that bookkeeping for the map flow.
		var return_screen := RunState.combat_return_screen
		if return_screen == "dungeon_map":
			_run.map.mark_current_cleared()
		var banner := "Victory!\nLoot (%d): %s" % [loot.size(), _loot_label(loot)]
		_show_result(banner)
		_after_run_beat(1.2, return_screen, false)


## Hold the result banner for `delay` seconds, then transition. `end_run`
## stamps the debrief into GameState so ResultsScreen can read it on _ready.
func _after_run_beat(delay: float, screen: String, end_run: bool) -> void:
	var go := func() -> void:
		if end_run:
			GameState.end_run(_run.to_summary())  # stamp the debrief first…
			RunState.clear_run()                  # …then drop the finished run
		SignalBus.screen_transition_requested.emit(screen)
	get_tree().create_timer(delay).timeout.connect(go)


## Loot is a RANDOM drop on victory — decoupled from the cards you answered
## (answered = due reviews → knowledge; looted = random drops → economy). Each
## drop rolls its own rarity (M3, decision D7): depth, this room's correct
## streak, and any clutch recall all bias the roll up. Instances drop raw —
## grading is a town craft (M4).
func _roll_loot() -> Array[CardInstance]:
	var pool: Array[String] = []
	for cd in GameState.character_db.get_all():
		pool.append(cd.get_card_id())
	pool.shuffle()
	var depth := _room.depth if _room != null else 0
	var n := mini(_rng.randi_range(1, 3), pool.size())
	var drops: Array[CardInstance] = []
	for i in n:
		var rarity := RarityRoll.roll(depth, _streak, _clutch, _rng)
		drops.append(CardInstance.create(pool[i], rarity, depth))
	return drops


## "好 [R], 大 [C]" — compact loot list for the victory banner.
func _loot_label(loot: Array) -> String:
	if loot.is_empty():
		return "—"
	var parts: Array[String] = []
	for ci in loot:
		parts.append(ci.display_label())
	return ", ".join(parts)


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
		var dmg := int(res.get("damage", 0))
		if res.get("crit", false):
			# Crits read louder: gold, bigger, an extra shake.
			_shake(_mob_views[idx], _mob_origins[idx])
			_float_text(anchor, "-%d CRIT!" % dmg, Color(1.0, 0.85, 0.2), 62)
		else:
			_float_text(anchor, "-%d" % dmg, Color(1.0, 0.55, 0.3), 46)
	else:
		_float_text(anchor, "Miss", Color(0.72, 0.72, 0.72), 34)


## The limit break reads as a screen-clearing burst: the hero flares and pops,
## then every struck mob shakes, flashes, and takes a loud gold damage float.
func _animate_limit_break(res: Dictionary) -> void:
	_flash(_hero_body, HERO_COLOR)
	var hero_t := _hero_view.create_tween()
	hero_t.tween_property(_hero_view, "scale", Vector2(1.25, 1.25), 0.1).set_trans(Tween.TRANS_BACK)
	hero_t.tween_property(_hero_view, "scale", Vector2.ONE, 0.16).set_ease(Tween.EASE_IN)
	for hit in res.get("hits", []):
		var idx: int = hit.get("mob_index", -1)
		if idx < 0 or idx >= _mob_views.size():
			continue
		_shake(_mob_views[idx], _mob_origins[idx])
		_flash(_mob_bodies[idx], MOB_COLOR)
		var anchor := _mob_origins[idx] + Vector2(MOB_SIZE.x * 0.5, -8)
		_float_text(anchor, "-%d!" % int(hit.get("damage", 0)), Color(1.0, 0.85, 0.2), 58)


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
	_hero_view.pivot_offset = HERO_SIZE * 0.5  # limit-break pop scales from center
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

	# Teach button — shown only for first-sight cards (overlays the answer area,
	# which is hidden during a teach beat).
	_teach_button = Button.new()
	_teach_button.custom_minimum_size = ANSWER_BTN
	_teach_button.position = ANSWER_START
	_teach_button.add_theme_font_size_override("font_size", 26)
	_teach_button.visible = false
	_teach_button.pressed.connect(_on_teach_pressed)
	add_child(_teach_button)

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

	# Staked-kit bonuses (M5). Text is set once the loadout is assembled in _ready.
	_kit_label = _label("")
	_kit_label.add_theme_font_size_override("font_size", 15)
	_kit_label.add_theme_color_override("font_color", Color(0.62, 0.82, 0.66))
	_kit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_kit_label.custom_minimum_size = Vector2(INFO_PANEL_SIZE.x - 44, 0)
	vb.add_child(_kit_label)

	vb.add_child(_label("HP"))
	_hero_hp_bar = _make_bar(INFO_PANEL_SIZE.x - 44, 24, Color(0.4, 0.8, 0.5))
	vb.add_child(_hero_hp_bar)

	vb.add_child(_label("ATB — answer right to charge, then strike"))
	_player_atb_bar = _make_bar(INFO_PANEL_SIZE.x - 44, 24, Color(0.35, 0.7, 1.0))
	vb.add_child(_player_atb_bar)

	# LIMIT gauge — charged by clutch (about-to-forget) recalls; full → unleash.
	vb.add_child(_label("LIMIT — clutch recalls charge it"))
	_limit_bar = _make_bar(INFO_PANEL_SIZE.x - 44, 24, Color(1.0, 0.7, 0.2))
	_limit_bar.value = 0.0
	vb.add_child(_limit_bar)

	_limit_button = Button.new()
	_limit_button.text = "⚡ LIMIT BREAK"
	_limit_button.custom_minimum_size = Vector2(INFO_PANEL_SIZE.x - 44, 40)
	_limit_button.add_theme_font_size_override("font_size", 22)
	_limit_button.disabled = true
	_limit_button.pressed.connect(_on_limit_pressed)
	vb.add_child(_limit_button)


func _refresh_status() -> void:
	if _hero_hp_bar:
		_hero_hp_bar.max_value = _combat.player_max_hp
		_hero_hp_bar.value = _combat.player_hp
	if _player_atb_bar:
		_player_atb_bar.value = _combat.player_atb
	if _limit_bar:
		_limit_bar.value = _combat.limit
	if _limit_button:
		var limit_ready := _combat.limit_ready() and not _finished
		_limit_button.disabled = not limit_ready
		# Glow gold when armed so the payoff reads at a glance.
		_limit_button.modulate = Color(1.0, 0.9, 0.4) if limit_ready else Color.WHITE
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
