## GameScreen — Main gameplay screen managing the card challenge flow.
## Orchestrates ChallengePresenter, tracks round progress, records reviews,
## and transitions to results when the pack is complete or hearts run out.
class_name GameScreen
extends Control

@onready var _challenge_presenter: ChallengePresenter = $ChallengePresenter if has_node("ChallengePresenter") else null
@onready var _heart_display: Control = $HeartDisplay if has_node("HeartDisplay") else null
@onready var _combo_counter: Control = $ComboCounter if has_node("ComboCounter") else null
@onready var _coin_counter: Control = $CoinCounter if has_node("CoinCounter") else null
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
var _drop_calculator: DropCalculator


func _ready() -> void:
	_answer_generator = AnswerGenerator.new(GameState.character_db)
	_drop_calculator = DropCalculator.new(null, null, GameState.radical_db)

	if _challenge_presenter:
		_challenge_presenter.challenge_completed.connect(_on_challenge_completed)

	SignalBus.hearts_changed.connect(_on_hearts_changed)
	SignalBus.combo_incremented.connect(_on_combo_incremented)
	SignalBus.combo_broken.connect(_on_combo_broken)
	SignalBus.all_hearts_lost.connect(_on_all_hearts_lost)
	SignalBus.card_presented.connect(_on_card_presented)

	_connect_answer_buttons()
	_start_session()


func _exit_tree() -> void:
	SignalBus.hearts_changed.disconnect(_on_hearts_changed)
	SignalBus.combo_incremented.disconnect(_on_combo_incremented)
	SignalBus.combo_broken.disconnect(_on_combo_broken)
	SignalBus.all_hearts_lost.disconnect(_on_all_hearts_lost)
	SignalBus.card_presented.disconnect(_on_card_presented)


func _start_session() -> void:
	print("[GameScreen] _start_session called")
	print("[GameScreen] GameState.is_in_run = ", GameState.is_in_run)
	print("[GameScreen] GameState.current_pack = ", GameState.current_pack)
	print("[GameScreen] character_db loaded = ", GameState.character_db.is_loaded(), ", count = ", GameState.character_db.get_count())
	print("[GameScreen] review_scheduler card_states count = ", GameState.review_scheduler.card_states.size())

	_pack = GameState.current_pack
	if _pack == null:
		# Curate a fresh pack if none was set
		print("[GameScreen] No current_pack, curating fresh pack...")
		var now := Time.get_unix_time_from_system()
		var new_ids := GameState.review_scheduler.get_new_card_ids()
		print("[GameScreen] new_card_ids count = ", new_ids.size())
		_pack = GameState.review_scheduler.curate_pack(now, SrsConfig.PACK_SIZE_DEFAULT, new_ids)
		GameState.current_pack = _pack

	print("[GameScreen] Pack total = ", _pack.get_total_count())
	print("[GameScreen]   struggling = ", _pack.struggling_cards.size())
	print("[GameScreen]   common = ", _pack.common_cards.size())
	print("[GameScreen]   new = ", _pack.new_cards.size())
	print("[GameScreen]   returning_mastered = ", _pack.returning_mastered.size())

	if _pack.presentation_order.is_empty():
		_pack.build_presentation_order()

	_card_index = 0
	_total_cards = _pack.presentation_order.size()
	_correct_count = 0
	_is_transitioning = false

	print("[GameScreen] presentation_order size = ", _total_cards)
	if _total_cards > 0:
		print("[GameScreen] first few cards: ", _pack.presentation_order.slice(0, mini(5, _total_cards)))

	_update_progress()
	AudioManager.play_music("gameplay")
	_present_next_card()


func _present_next_card() -> void:
	print("[GameScreen] _present_next_card: index=%d / total=%d" % [_card_index, _total_cards])
	if _card_index >= _total_cards:
		print("[GameScreen] All cards done, going to pack_complete")
		_on_pack_complete()
		return

	var card_id: String = _pack.presentation_order[_card_index]
	var card_data: CharacterData = GameState.character_db.get_character(card_id)
	print("[GameScreen] card_id='%s', card_data=%s" % [card_id, "found" if card_data else "NULL"])
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

	if _challenge_presenter:
		_challenge_presenter.setup(_answer_generator)
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

	# Record the answer in GameState
	GameState.record_answer(correct)

	# Record in SRS scheduler
	var now := Time.get_unix_time_from_system()
	var review_result: Dictionary = GameState.review_scheduler.record_review(
		card_id, challenge_type, rating, now
	)

	# Process drops on correct answer
	if correct:
		_correct_count += 1
		var card_data: CharacterData = GameState.character_db.get_character(card_id)
		if card_data:
			var loot_rarity: SrsEnums.LootRarity = GameState.review_scheduler.get_loot_rarity(
				card_id, challenge_type, now
			)
			var drops: Dictionary = _drop_calculator.calculate_drops(
				card_data,
				loot_rarity,
				GameState.current_combo,
				GameState.player_hsk_level,
				GameState.equipped_radicals
			)
			_apply_drops(drops)

		# Check for tier promotion
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

	# Clear answer labels
	_clear_answer_labels()

	# Advance to next card
	_card_index += 1
	_update_progress()

	# Delay before next card for visual feedback
	_is_transitioning = true
	var timer := get_tree().create_timer(0.6)
	timer.timeout.connect(_on_transition_timeout)


func _on_transition_timeout() -> void:
	_is_transitioning = false
	_present_next_card()


func _apply_drops(drops: Dictionary) -> void:
	var coins: int = drops.get("coins", 0)
	if coins > 0:
		GameState.add_coins(coins)

	var tiles: Array = drops.get("tiles", [])
	for tile in tiles:
		GameState.add_tiles(str(tile))


func _on_pack_complete() -> void:
	GameState.end_run()
	SignalBus.screen_transition_requested.emit("results")


func _on_all_hearts_lost() -> void:
	# Game over -- transition to results
	_is_transitioning = true
	GameState.end_run()
	SignalBus.screen_transition_requested.emit("results")


func _on_hearts_changed(current: int, max_hearts: int) -> void:
	if _heart_display and _heart_display.has_method("set_hearts"):
		_heart_display.set_hearts(current, max_hearts)


func _on_combo_incremented(combo_count: int) -> void:
	if _combo_counter and _combo_counter.has_method("set_combo"):
		_combo_counter.set_combo(combo_count)


func _on_combo_broken(_final_count: int) -> void:
	if _combo_counter and _combo_counter.has_method("set_combo"):
		_combo_counter.set_combo(0)


func _update_progress() -> void:
	if _progress_bar and _progress_bar.has_method("set_progress"):
		_progress_bar.set_progress(_card_index, _total_cards)
	if _coin_counter and _coin_counter.has_method("set_count"):
		var display_coins: int = GameState.run_coins_earned if GameState.is_in_run else GameState.total_coins
		_coin_counter.set_count(display_coins)


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
		GameState.end_run()
	SignalBus.screen_transition_requested.emit("main_menu")
