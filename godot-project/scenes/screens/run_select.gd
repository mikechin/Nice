## RunSelect — Run type selection screen offering Easy Run and Challenge Run.
## Shows description and card mix info for each mode.
class_name RunSelect
extends Control

@onready var _easy_button: Button = $ModeContainer/EasyButton if has_node("ModeContainer/EasyButton") else null
@onready var _challenge_button: Button = $ModeContainer/ChallengeButton if has_node("ModeContainer/ChallengeButton") else null
@onready var _easy_description: Label = $ModeContainer/EasyDescription if has_node("ModeContainer/EasyDescription") else null
@onready var _challenge_description: Label = $ModeContainer/ChallengeDescription if has_node("ModeContainer/ChallengeDescription") else null
@onready var _due_count_label: Label = $DueCountLabel if has_node("DueCountLabel") else null
@onready var _back_button: Button = $BackButton if has_node("BackButton") else null
@onready var _title_label: Label = $TitleLabel if has_node("TitleLabel") else null


func _ready() -> void:
	_warn_missing_nodes()
	if _easy_button:
		_easy_button.pressed.connect(_on_easy_pressed)
	if _challenge_button:
		_challenge_button.pressed.connect(_on_challenge_pressed)
	if _back_button:
		_back_button.pressed.connect(_on_back_pressed)

	_update_descriptions()
	_update_due_count()


func _update_descriptions() -> void:
	if _title_label:
		_title_label.text = "Select Run Type"

	if _easy_description:
		_easy_description.text = "Relaxed pace. More known cards, fewer new ones. Great for daily review."

	if _challenge_description:
		_challenge_description.text = "High stakes. More new and due cards. Boss rounds every 3 rounds."


func _update_due_count() -> void:
	if _due_count_label == null:
		return
	var now := Time.get_unix_time_from_system()
	var due_cards: Array[CardState] = GameState.review_scheduler.get_due_cards(now)
	var new_cards: Array[String] = GameState.review_scheduler.get_new_card_ids()
	_due_count_label.text = "%d cards due, %d new available" % [due_cards.size(), new_cards.size()]


func _on_easy_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	_start_run("easy")


func _on_challenge_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	_start_run("challenge")


func _start_run(run_type: String) -> void:
	# Curate a pack for this run
	var now := Time.get_unix_time_from_system()
	var new_ids: Array = GameState.review_scheduler.get_new_card_ids()
	print("[RunSelect] _start_run('%s')" % run_type)
	print("[RunSelect] new_ids count = ", new_ids.size())
	print("[RunSelect] card_states count = ", GameState.review_scheduler.card_states.size())
	var pack: PackData = GameState.review_scheduler.curate_pack(now, SrsConfig.PACK_SIZE_DEFAULT, new_ids)
	print("[RunSelect] Pack curated: total=%d, new=%d, struggling=%d, common=%d, returning=%d" % [
		pack.get_total_count(), pack.new_cards.size(), pack.struggling_cards.size(),
		pack.common_cards.size(), pack.returning_mastered.size()
	])
	print("[RunSelect] presentation_order size = ", pack.presentation_order.size())
	GameState.current_pack = pack

	# Start the run through GameState
	GameState.start_run(run_type)

	SignalBus.screen_transition_requested.emit("game")


func _on_back_pressed() -> void:
	SignalBus.screen_transition_requested.emit("main_menu")


func _warn_missing_nodes() -> void:
	if _easy_button == null:
		push_warning("run_select.gd: missing node _easy_button")
	if _challenge_button == null:
		push_warning("run_select.gd: missing node _challenge_button")
	if _easy_description == null:
		push_warning("run_select.gd: missing node _easy_description")
	if _challenge_description == null:
		push_warning("run_select.gd: missing node _challenge_description")
	if _due_count_label == null:
		push_warning("run_select.gd: missing node _due_count_label")
	if _back_button == null:
		push_warning("run_select.gd: missing node _back_button")
	if _title_label == null:
		push_warning("run_select.gd: missing node _title_label")
