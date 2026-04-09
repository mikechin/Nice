## BossRoundScreen — Boss round UI for sentence-building challenges.
## Creates a BossRoundManager, generates the challenge, shows sentence tiles,
## and handles player submission and scoring.
class_name BossRoundScreen
extends Control

@onready var _title_label: Label = $TitleLabel if has_node("TitleLabel") else null
@onready var _type_label: Label = $TypeLabel if has_node("TypeLabel") else null
@onready var _prompt_label: Label = $PromptLabel if has_node("PromptLabel") else null
@onready var _hint_label: Label = $HintLabel if has_node("HintLabel") else null
@onready var _sentence_container: HBoxContainer = $SentenceContainer if has_node("SentenceContainer") else null
@onready var _tile_container: GridContainer = $TileContainer if has_node("TileContainer") else null
@onready var _submit_button: Button = $SubmitButton if has_node("SubmitButton") else null
@onready var _clear_button: Button = $ClearButton if has_node("ClearButton") else null
@onready var _result_label: Label = $ResultLabel if has_node("ResultLabel") else null
@onready var _score_label: Label = $ScoreLabel if has_node("ScoreLabel") else null
@onready var _continue_button: Button = $ContinueButton if has_node("ContinueButton") else null

var _boss_manager: BossRoundManager
var _sentence_builder: SentenceBuilder
var _challenge: Dictionary = {}
var _is_submitted: bool = false
var _slot_scene: PackedScene
var _tile_scene: PackedScene


func _ready() -> void:
	_warn_missing_nodes()
	_boss_manager = BossRoundManager.new(GameState.sentence_db)
	_sentence_builder = SentenceBuilder.new()
	_sentence_builder.set_available_tiles(GameState.tile_inventory.duplicate())

	if _submit_button:
		_submit_button.pressed.connect(_on_submit_pressed)
	if _clear_button:
		_clear_button.pressed.connect(_on_clear_pressed)
	if _continue_button:
		_continue_button.pressed.connect(_on_continue_pressed)
		_continue_button.visible = false

	if ResourceLoader.exists("res://scenes/components/sentence_slot.tscn"):
		_slot_scene = load("res://scenes/components/sentence_slot.tscn")
	if ResourceLoader.exists("res://scenes/components/tile_slot.tscn"):
		_tile_scene = load("res://scenes/components/tile_slot.tscn")

	_generate_challenge()
	AudioManager.play_boss_start()


func _generate_challenge() -> void:
	_challenge = _boss_manager.generate_boss_round(
		GameState.player_hsk_level,
		GameState.tile_inventory
	)

	if _challenge.is_empty():
		# No valid boss challenge available -- skip
		if _title_label:
			_title_label.text = "Boss Round"
		if _prompt_label:
			_prompt_label.text = "No sentence available for your current tiles."
		if _submit_button:
			_submit_button.visible = false
		return

	_display_challenge()
	_populate_available_tiles()


func _display_challenge() -> void:
	var boss_type_name: String = _boss_manager.get_boss_type_name()

	if _title_label:
		_title_label.text = "BOSS ROUND"
	if _type_label:
		_type_label.text = boss_type_name

	var boss_type: BossRoundManager.BossType = _challenge.get("boss_type", BossRoundManager.BossType.FILL_BLANK)

	match boss_type:
		BossRoundManager.BossType.FILL_BLANK:
			if _prompt_label:
				_prompt_label.text = _challenge.get("display", "")
			if _hint_label:
				_hint_label.text = "Meaning: %s" % _challenge.get("meaning", "")

		BossRoundManager.BossType.SCRAMBLE:
			var scrambled: Array = _challenge.get("scrambled_characters", [])
			if _prompt_label:
				_prompt_label.text = "Unscramble: %s" % " ".join(scrambled)
			if _hint_label:
				_hint_label.text = "Meaning: %s" % _challenge.get("meaning", "")
			# Pre-populate tile area with scrambled characters
			_populate_scramble_tiles(scrambled)

		BossRoundManager.BossType.FREE_BUILD:
			if _prompt_label:
				_prompt_label.text = "Build a sentence meaning:"
			if _hint_label:
				var char_count: int = _challenge.get("hint_character_count", 0)
				_hint_label.text = "\"%s\" (%d characters)" % [_challenge.get("meaning", ""), char_count]


func _populate_available_tiles() -> void:
	if _tile_container == null:
		return
	for child in _tile_container.get_children():
		child.queue_free()

	var available: Dictionary = _sentence_builder.available_tiles
	for ch in available:
		var count: int = available[ch]
		for i in count:
			var tile: Control = _create_tile(ch)
			_tile_container.add_child(tile)


func _populate_scramble_tiles(characters: Array) -> void:
	if _tile_container == null:
		return
	for child in _tile_container.get_children():
		child.queue_free()

	for ch in characters:
		var tile: Control = _create_tile(str(ch))
		_tile_container.add_child(tile)


func _create_tile(character: String) -> Control:
	var tile: Control
	if _tile_scene:
		tile = _tile_scene.instantiate()
	else:
		tile = _create_fallback_tile(character)

	if tile.has_method("setup_tile"):
		tile.setup_tile(character)

	# Connect tap to place
	if tile is BaseButton:
		tile.pressed.connect(_on_tile_tapped.bind(character, tile))
	elif tile.has_signal("tile_tapped"):
		tile.tile_tapped.connect(_on_tile_tapped.bind(character, tile))
	else:
		# Wrap in a button for interaction
		tile.gui_input.connect(_on_tile_gui_input.bind(character, tile))

	return tile


func _create_fallback_tile(character: String) -> Button:
	var btn := Button.new()
	btn.text = character
	btn.custom_minimum_size = Vector2(48, 48)
	return btn


func _on_tile_tapped(character: String, tile_node: Control) -> void:
	if _is_submitted:
		return
	if _sentence_builder.place_tile(character):
		tile_node.visible = false
		_update_sentence_display()


func _on_tile_gui_input(event: InputEvent, character: String, tile_node: Control) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_tile_tapped(character, tile_node)


func _update_sentence_display() -> void:
	if _sentence_container == null:
		return
	for child in _sentence_container.get_children():
		child.queue_free()

	for i in _sentence_builder.placed_tiles.size():
		var ch: String = _sentence_builder.placed_tiles[i]
		var slot: Control
		if _slot_scene:
			slot = _slot_scene.instantiate()
			if slot.has_method("setup_slot"):
				slot.setup_slot(ch, i)
		else:
			slot = Label.new()
			slot.text = ch

		if slot.has_signal("slot_tapped"):
			slot.slot_tapped.connect(_on_slot_tapped.bind(i))
		else:
			slot.gui_input.connect(_on_slot_gui_input.bind(i))

		_sentence_container.add_child(slot)


func _on_slot_tapped(position: int) -> void:
	if _is_submitted:
		return
	var removed: String = _sentence_builder.remove_tile(position)
	if removed != "":
		_update_sentence_display()
		_populate_available_tiles()


func _on_slot_gui_input(event: InputEvent, position: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_slot_tapped(position)


func _on_submit_pressed() -> void:
	if _is_submitted:
		return

	var answer: String = _sentence_builder.get_current_sentence()
	if answer.is_empty():
		return

	_is_submitted = true
	var result: Dictionary = _boss_manager.submit_answer(answer)
	var correct: bool = result.get("correct", false)
	var score: int = result.get("score", 0)

	if _result_label:
		_result_label.visible = true
		if correct:
			_result_label.text = "Correct!"
			_result_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
			AudioManager.play_correct()
		else:
			_result_label.text = "Incorrect"
			_result_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
			AudioManager.play_wrong()

	if _score_label:
		_score_label.visible = true
		_score_label.text = "+%d points" % score if correct else ""

	if _submit_button:
		_submit_button.visible = false
	if _clear_button:
		_clear_button.visible = false
	if _continue_button:
		_continue_button.visible = true

	# Add score as coins
	if correct and score > 0:
		GameState.add_coins(score)


func _on_clear_pressed() -> void:
	if _is_submitted:
		return
	_sentence_builder.clear_sentence()
	_update_sentence_display()
	_populate_available_tiles()


func _on_continue_pressed() -> void:
	# Return to game flow
	SignalBus.screen_transition_requested.emit("game")


func _warn_missing_nodes() -> void:
	if _title_label == null:
		push_warning("boss_round_screen.gd: missing node _title_label")
	if _type_label == null:
		push_warning("boss_round_screen.gd: missing node _type_label")
	if _prompt_label == null:
		push_warning("boss_round_screen.gd: missing node _prompt_label")
	if _hint_label == null:
		push_warning("boss_round_screen.gd: missing node _hint_label")
	if _sentence_container == null:
		push_warning("boss_round_screen.gd: missing node _sentence_container")
	if _tile_container == null:
		push_warning("boss_round_screen.gd: missing node _tile_container")
	if _submit_button == null:
		push_warning("boss_round_screen.gd: missing node _submit_button")
	if _clear_button == null:
		push_warning("boss_round_screen.gd: missing node _clear_button")
	if _result_label == null:
		push_warning("boss_round_screen.gd: missing node _result_label")
	if _score_label == null:
		push_warning("boss_round_screen.gd: missing node _score_label")
	if _continue_button == null:
		push_warning("boss_round_screen.gd: missing node _continue_button")
