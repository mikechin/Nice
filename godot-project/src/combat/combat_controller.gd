## CombatController — drives one ATB combat room (Model A vertical slice).
##
## Wires the tested-pure CombatState (player HP + ATB vs. mob HP + timers) to
## the shared AnswerInput, renders a code-built UI, and routes every first
## answer through GameState.review_scheduler.record_review — the one honest
## FSRS commit. Knowledge is the fuel: a correct answer charges your ATB; a
## full gauge auto-strikes the targeted mob; mobs chip your HP on their own
## timer (the soft clock). Clear all mobs → a RANDOM loot drop (decoupled
## from the cards you answered). Layout is crude — a playable slice, not the
## final scene.
class_name CombatController
extends Control

const CardDisplayScene := preload("res://scenes/components/card_display.tscn")
const DIRECTIONS: Array[String] = ["up", "down", "left", "right"]
const ARROWS := {"up": "↑", "down": "↓", "left": "←", "right": "→"}

# --- M1 placeholder tuning ---
const PLAYER_HP := 30
const ATB_PER_CORRECT := 0.34   # ~3 correct answers to charge an attack
const ATTACK_DAMAGE := 3
const MAX_MOBS := 3
const FEEDBACK_DELAY := 0.4

var _answer_generator: AnswerGenerator
var _answer_input: AnswerInput
var _rng: RandomNumberGenerator
var _combat: CombatState

var _card_queue: Array[String] = []
var _queue_index: int = 0
var _busy: bool = false
var _finished: bool = false

# UI
var _player_hp_bar: ProgressBar
var _player_atb_bar: ProgressBar
var _mobs_row: HBoxContainer
var _mob_buttons: Array[Button] = []
var _card_display: CardDisplay
var _challenge_label: Label
var _answer_buttons: Dictionary = {}
var _result_label: Label


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_answer_generator = AnswerGenerator.new(GameState.character_db)
	_answer_input = AnswerInput.new()
	add_child(_answer_input)
	_answer_input.setup(_answer_generator, null, null)
	_answer_input.answered.connect(_on_answered)

	_build_ui()
	_card_queue = _pick_card_ids(50)
	_combat = CombatState.create(PLAYER_HP, _build_mobs(), ATB_PER_CORRECT, ATTACK_DAMAGE)
	_build_mob_buttons()
	if _card_queue.is_empty() or _combat.current_mob() == null:
		_show_result("No cards / mobs available to fight.")
		return
	_refresh_status()
	_present_next()
	set_process(true)


func _process(delta: float) -> void:
	if _finished or _combat == null:
		return
	_combat.tick(delta)  # mob gauges fill; ready mobs chip the player's HP
	_refresh_status()
	if _combat.is_over():
		_finish()


# -- setup -------------------------------------------------------------------

func _build_mobs() -> Array[CombatMob]:
	var mobs: Array[CombatMob] = []
	for i in _rng.randi_range(1, MAX_MOBS):
		var hp := _rng.randi_range(4, 7)
		var atk := _rng.randi_range(2, 4)
		var rate := _rng.randf_range(0.03, 0.055)  # slowed 75% — ~18–33s per strike
		mobs.append(CombatMob.create("Mob %d" % (i + 1), hp, atk, rate))
	return mobs


## The prompts are due reviews (knowledge) — NOT the mobs and NOT the loot.
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
		btn.text = "%s  %s" % [ARROWS[dir], answers.get(dir, "")]
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
	AudioManager.play_correct() if correct else AudioManager.play_wrong()

	_combat.answer(correct)                       # correct charges the ATB gauge
	if _combat.player_attack_ready():
		_combat.player_attack()                   # full gauge → auto-strike the target

	_busy = true
	for dir in DIRECTIONS:
		_answer_buttons[dir].disabled = true
	_refresh_status()

	if _combat.is_over():
		_finish()
		return
	get_tree().create_timer(FEEDBACK_DELAY).timeout.connect(_present_next)


func _on_mob_tapped(index: int) -> void:
	if _busy or _finished:
		return
	_combat.set_target(index)
	_refresh_status()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	set_process(false)
	if _combat.outcome() == CombatState.Outcome.LOST:
		_show_result("You died. Haul lost.")
	else:
		var loot := _roll_loot()
		_show_result("Victory!\nLoot (%d): %s" % [loot.size(), ", ".join(loot) if not loot.is_empty() else "—"])


## Loot is a RANDOM drop on victory — decoupled from the cards you answered.
func _roll_loot() -> Array[String]:
	var pool: Array[String] = []
	for cd in GameState.character_db.get_all():
		pool.append(cd.character)
	pool.shuffle()
	return pool.slice(0, mini(_rng.randi_range(1, 3), pool.size()))


# -- UI (built in code; combat.tscn is just the root + script) ---------------

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	# Player status: HP + ATB bars.
	var player_box := VBoxContainer.new()
	player_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	player_box.custom_minimum_size = Vector2(440, 0)
	root.add_child(player_box)
	player_box.add_child(_label("HP"))
	_player_hp_bar = _make_bar(Color(0.9, 0.3, 0.35), PLAYER_HP, PLAYER_HP)
	player_box.add_child(_player_hp_bar)
	player_box.add_child(_label("ATB — answer correctly to charge, then auto-attack"))
	_player_atb_bar = _make_bar(Color(0.35, 0.7, 1.0), 1.0, 0.0)
	player_box.add_child(_player_atb_bar)

	# Mob roster (tap a mob to target it).
	_mobs_row = HBoxContainer.new()
	_mobs_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_mobs_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_mobs_row.add_theme_constant_override("separation", 16)
	root.add_child(_mobs_row)

	# Prompt card.
	_card_display = CardDisplayScene.instantiate()
	_card_display.custom_minimum_size = Vector2(540, 260)
	_card_display.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(_card_display)
	_answer_input.card_display = _card_display

	_challenge_label = _label("")
	_challenge_label.add_theme_font_size_override("font_size", 24)
	root.add_child(_challenge_label)

	# Choices as a directional cross.
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	root.add_child(grid)
	var cross := ["", "up", "", "left", "", "right", "", "down", ""]
	for slot in cross:
		if slot == "":
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(320, 84)
			grid.add_child(spacer)
		else:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(320, 84)
			btn.add_theme_font_size_override("font_size", 24)
			btn.pressed.connect(_on_direction.bind(slot))
			grid.add_child(btn)
			_answer_buttons[slot] = btn

	_result_label = _label("")
	_result_label.add_theme_font_size_override("font_size", 30)
	_result_label.visible = false
	root.add_child(_result_label)


func _build_mob_buttons() -> void:
	_mob_buttons.clear()
	for i in _combat.mobs.size():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(260, 84)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_mob_tapped.bind(i))
		_mobs_row.add_child(btn)
		_mob_buttons.append(btn)


func _refresh_status() -> void:
	if _player_hp_bar:
		_player_hp_bar.value = _combat.player_hp
	if _player_atb_bar:
		_player_atb_bar.value = _combat.player_atb
	for i in _mob_buttons.size():
		var btn := _mob_buttons[i]
		var mob: CombatMob = _combat.mobs[i]
		if mob.is_alive():
			var marker := "▶ " if i == _combat.current_target_index() else ""
			btn.text = "%s%s   HP %d/%d   ATB %d%%" % [marker, mob.label, mob.hp, mob.max_hp, roundi(mob.atb * 100.0)]
			btn.disabled = false
		else:
			btn.text = "%s  (defeated)" % mob.label
			btn.disabled = true


func _make_bar(color: Color, maxv: float, initial: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = maxv
	bar.value = initial
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(440, 22)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
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
		_result_label.visible = true
