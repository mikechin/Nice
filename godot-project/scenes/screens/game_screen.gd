## GameScreen — Main gameplay screen managing the card challenge flow.
## Orchestrates ChallengePresenter, tracks round progress, records reviews,
## and transitions to results when the pack is complete.
class_name GameScreen
extends Control

@onready var _challenge_presenter: ChallengePresenter = $ChallengePresenter if has_node("ChallengePresenter") else null
@onready var _progress_bar: Control = $ProgressBar if has_node("ProgressBar") else null
@onready var _card_prompt_label: Label = $CardPromptLabel if has_node("CardPromptLabel") else null
@onready var _challenge_type_label: Label = $ChallengeTypeLabel if has_node("ChallengeTypeLabel") else null
@onready var _answer_labels: Dictionary = {
	"up": $AnswerUp if has_node("AnswerUp") else null,
	"down": $AnswerDown if has_node("AnswerDown") else null,
	"left": $AnswerLeft if has_node("AnswerLeft") else null,
	"right": $AnswerRight if has_node("AnswerRight") else null,
}

var _pack: PackData
var _card_index: int = 0
var _total_cards: int = 0
var _correct_count: int = 0
var _is_transitioning: bool = false
var _answer_generator: AnswerGenerator
var _run_manager: RunManager
var _bonus_manager: BonusRoundManager
var _rng: RandomNumberGenerator
## True between bonus_round_started and card_resolved; lets the per-stage
## challenge_completed handler skip per-card bookkeeping for bonus stages.
var _in_bonus_stage: bool = false


func _ready() -> void:
	_warn_missing_nodes()
	_answer_generator = AnswerGenerator.new(GameState.character_db)
	_bonus_manager = BonusRoundManager.new()
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

	if _challenge_presenter:
		_challenge_presenter.challenge_completed.connect(_on_challenge_completed)
		_challenge_presenter.bonus_round_started.connect(_on_bonus_round_started)
		_challenge_presenter.card_resolved.connect(_on_card_resolved)

	SignalBus.card_presented.connect(_on_card_presented)

	_connect_answer_buttons()
	_start_session()


func _exit_tree() -> void:
	SignalBus.card_presented.disconnect(_on_card_presented)


func _start_session() -> void:
	_pack = GameState.current_pack
	if _pack == null:
		var now := Time.get_unix_time_from_system()
		var new_ids := GameState.review_scheduler.get_new_card_ids()
		_pack = GameState.review_scheduler.curate_pack(now, SrsConfig.PACK_SIZE_DEFAULT, new_ids)
		GameState.current_pack = _pack

	if _pack.presentation_order.is_empty():
		_pack.build_presentation_order()

	_card_index = 0
	_total_cards = _pack.presentation_order.size()
	_correct_count = 0
	_is_transitioning = false

	_run_manager = RunManager.new()
	_run_manager.start_run(_pack)

	_update_progress()
	AudioManager.play_music("gameplay")
	_present_next_card()


func _present_next_card() -> void:
	if _card_index >= _total_cards:
		_on_pack_complete()
		return

	var card_id: String = _pack.presentation_order[_card_index]
	var card_data: CharacterData = GameState.character_db.get_character(card_id)
	if card_data == null:
		# Skip missing cards
		_card_index += 1
		_present_next_card()
		return

	var challenge_type: String = GameState.review_scheduler.select_challenge_type(card_id)
	var now := Time.get_unix_time_from_system()
	var loot_rarity: SrsEnums.LootRarity = GameState.review_scheduler.get_loot_rarity(
		card_id, challenge_type, now
	)

	if _card_prompt_label:
		_card_prompt_label.remove_theme_color_override("font_color")

	_in_bonus_stage = false

	if _challenge_presenter:
		_challenge_presenter.setup(_answer_generator, null, null, _bonus_manager, _rng)
		_challenge_presenter.present_challenge(card_data, challenge_type, loot_rarity)


func _connect_answer_buttons() -> void:
	for dir_key in _answer_labels:
		var btn: Control = _answer_labels[dir_key]
		if btn is BaseButton:
			btn.pressed.connect(_on_answer_button_pressed.bind(dir_key))


func _on_answer_button_pressed(direction: String) -> void:
	if _is_transitioning:
		return
	if _challenge_presenter and _challenge_presenter.is_active():
		_challenge_presenter.submit_answer(direction)


func _on_card_presented(card_data: Dictionary, challenge_type: String) -> void:
	# Show the card prompt
	if _card_prompt_label:
		_card_prompt_label.text = _challenge_presenter.get_challenge_prompt(
			_challenge_presenter._current_card, challenge_type
		) if _challenge_presenter else ""
	if _challenge_type_label:
		var type_labels: Dictionary = {
			"meaning": "What does this mean?",
			"character": "Which character?",
			"pinyin": "What is the pinyin?",
			"tone": "What tone?",
		}
		_challenge_type_label.text = type_labels.get(challenge_type, "")

	# Update answer buttons from current answers
	if _challenge_presenter == null:
		return
	var answers: Dictionary = _challenge_presenter.get_current_answers()
	for dir_key in _answer_labels:
		var btn: Control = _answer_labels[dir_key]
		if btn is BaseButton:
			btn.text = answers.get(dir_key, "")
			btn.disabled = false
		elif btn and btn.has_method("set_answer"):
			var text: String = answers.get(dir_key, "")
			var is_correct: bool = dir_key == answers.get("correct_direction", "")
			btn.set_answer(text, is_correct)


func _on_challenge_completed(card_id: String, challenge_type: String, correct: bool, rating: int) -> void:
	if _is_transitioning:
		return

	# RunManager tracks per-card progress only — bonus stages share the
	# primary card and must not double-count toward round completion.
	if _run_manager and not _in_bonus_stage:
		_run_manager.on_card_answered(card_id, challenge_type, correct, rating)

	# SRS records every stage independently (per-card, per-challenge-type).
	var now := Time.get_unix_time_from_system()
	var review_result: Dictionary = GameState.review_scheduler.record_review(
		card_id, challenge_type, rating, now
	)

	if correct:
		var promotion: Dictionary = review_result.get("promotion", {})
		if promotion.get("promoted", false):
			AudioManager.play_tier_promotion()
			SignalBus.card_effect_requested.emit("tier_promotion", {"card_id": card_id})

		AudioManager.play_correct()
		if _card_prompt_label:
			_card_prompt_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	else:
		AudioManager.play_wrong()
		if _card_prompt_label:
			_card_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))


func _on_bonus_round_started(_card_id: String) -> void:
	_in_bonus_stage = true


func _on_card_resolved(card_id: String, primary_correct: bool, base_power: int, boosts: Array) -> void:
	if _is_transitioning:
		return

	if _run_manager:
		_run_manager.on_card_resolved(card_id, primary_correct, base_power, boosts)

	if primary_correct:
		_correct_count += 1

	_in_bonus_stage = false
	_clear_answer_labels()

	_card_index += 1
	_update_progress()

	_is_transitioning = true
	var timer := get_tree().create_timer(0.6)
	timer.timeout.connect(_on_transition_timeout)


func _on_transition_timeout() -> void:
	# SceneTreeTimer keeps firing even if the screen has exited the tree.
	if not is_inside_tree():
		return
	_is_transitioning = false
	_present_next_card()


func _on_pack_complete() -> void:
	if _run_manager:
		_run_manager.end_run()
	GameState.end_run(_run_manager.get_run_summary() if _run_manager else {})
	SignalBus.screen_transition_requested.emit("results")


func _update_progress() -> void:
	if _progress_bar and _progress_bar.has_method("set_progress"):
		_progress_bar.set_progress(_card_index, _total_cards)


func _clear_answer_labels() -> void:
	for dir_key in _answer_labels:
		var btn: Control = _answer_labels[dir_key]
		if btn is BaseButton:
			btn.text = ""
			btn.disabled = true
		elif btn and btn.has_method("clear_answer"):
			btn.clear_answer()
		elif btn and btn is Label:
			btn.text = ""


func _on_back_pressed() -> void:
	# Confirm exit mid-run
	if GameState.is_in_run:
		if _run_manager:
			_run_manager.end_run()
		GameState.end_run(_run_manager.get_run_summary() if _run_manager else {})
	SignalBus.screen_transition_requested.emit("main_menu")


func _warn_missing_nodes() -> void:
	if _challenge_presenter == null:
		push_warning("game_screen.gd: missing node _challenge_presenter")
	if _progress_bar == null:
		push_warning("game_screen.gd: missing node _progress_bar")
	if _card_prompt_label == null:
		push_warning("game_screen.gd: missing node _card_prompt_label")
	if _challenge_type_label == null:
		push_warning("game_screen.gd: missing node _challenge_type_label")
