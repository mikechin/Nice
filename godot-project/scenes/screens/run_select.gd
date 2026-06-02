## RunSelect — Pre-run screen. Shows the player how many cards are due
## and lets them start a single 12-card run.
class_name RunSelect
extends Control

@onready var _start_button: Button = $ModeContainer/StartButton if has_node("ModeContainer/StartButton") else null
@onready var _run_description: Label = $ModeContainer/RunDescription if has_node("ModeContainer/RunDescription") else null
@onready var _due_count_label: Label = $DueCountLabel if has_node("DueCountLabel") else null
@onready var _back_button: Button = $BackButton if has_node("BackButton") else null
@onready var _title_label: Label = $TitleLabel if has_node("TitleLabel") else null
@onready var _debug_tier_button: Button = $ModeContainer/DebugTierSampleButton if has_node("ModeContainer/DebugTierSampleButton") else null


func _ready() -> void:
	_warn_missing_nodes()
	if _start_button:
		_start_button.pressed.connect(_on_start_pressed)
	if _back_button:
		_back_button.pressed.connect(_on_back_pressed)
	if _debug_tier_button:
		_debug_tier_button.pressed.connect(_on_debug_tier_sample_pressed)

	_update_descriptions()
	_update_due_count()


func _update_descriptions() -> void:
	if _title_label:
		_title_label.text = "Today's Pack"

	if _run_description:
		_run_description.text = "%d cards. Cards you answer correctly will go into your hand for the board game." % SrsConfig.PACK_SIZE_DEFAULT


func _update_due_count() -> void:
	if _due_count_label == null:
		return
	var now := Time.get_unix_time_from_system()
	var due_cards: Array[CardState] = GameState.review_scheduler.get_due_cards(now)
	var new_cards: Array[String] = GameState.review_scheduler.get_new_card_ids()
	_due_count_label.text = "%d cards due, %d new available" % [due_cards.size(), new_cards.size()]


func _on_start_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	_start_run()


func _start_run() -> void:
	# Curate a pack for this run
	var now := Time.get_unix_time_from_system()
	var new_ids: Array = GameState.review_scheduler.get_new_card_ids()
	var pack: PackData = GameState.review_scheduler.curate_pack(now, SrsConfig.PACK_SIZE_DEFAULT, new_ids)
	GameState.current_pack = pack

	# Start the run through GameState
	GameState.start_run()

	SignalBus.screen_transition_requested.emit("game")


func _on_debug_tier_sample_pressed() -> void:
	# Builds a 4-card pack with one card per visual tier so the
	# CardDisplay rendering can be verified end-to-end.
	AudioManager.play_sfx("button_tap")
	var sample_cards := _pick_debug_sample_cards(4)
	if sample_cards.size() < 4:
		push_warning("run_select.gd: character_db has fewer than 4 cards; debug pack will be short")
	var pack := GameState.review_scheduler.curate_debug_tier_sample_pack(sample_cards)
	GameState.current_pack = pack
	GameState.start_run()
	SignalBus.screen_transition_requested.emit("game")


func _pick_debug_sample_cards(count: int) -> Array[CharacterData]:
	var picked: Array[CharacterData] = []
	if GameState.character_db == null:
		return picked
	var all := GameState.character_db.get_all()
	for i in mini(count, all.size()):
		picked.append(all[i])
	return picked


func _on_back_pressed() -> void:
	SignalBus.screen_transition_requested.emit("main_menu")


func _warn_missing_nodes() -> void:
	if _start_button == null:
		push_warning("run_select.gd: missing node _start_button")
	if _run_description == null:
		push_warning("run_select.gd: missing node _run_description")
	if _due_count_label == null:
		push_warning("run_select.gd: missing node _due_count_label")
	if _back_button == null:
		push_warning("run_select.gd: missing node _back_button")
	if _title_label == null:
		push_warning("run_select.gd: missing node _title_label")
	if _debug_tier_button == null:
		push_warning("run_select.gd: missing node _debug_tier_button")
