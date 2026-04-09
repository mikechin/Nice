## ResultsScreen — Shows run results including accuracy, combo, coins, and tiles earned.
## Pulls data from GameState's last run result. Offers Play Again and Main Menu buttons.
class_name ResultsScreen
extends Control

@onready var _accuracy_label: Label = $StatsContainer/AccuracyLabel if has_node("StatsContainer/AccuracyLabel") else null
@onready var _combo_label: Label = $StatsContainer/ComboLabel if has_node("StatsContainer/ComboLabel") else null
@onready var _coins_label: Label = $StatsContainer/CoinsLabel if has_node("StatsContainer/CoinsLabel") else null
@onready var _tiles_label: Label = $StatsContainer/TilesLabel if has_node("StatsContainer/TilesLabel") else null
@onready var _rounds_label: Label = $StatsContainer/RoundsLabel if has_node("StatsContainer/RoundsLabel") else null
@onready var _hearts_label: Label = $StatsContainer/HeartsLabel if has_node("StatsContainer/HeartsLabel") else null
@onready var _title_label: Label = $TitleLabel if has_node("TitleLabel") else null
@onready var _play_again_button: Button = $ButtonContainer/PlayAgainButton if has_node("ButtonContainer/PlayAgainButton") else null
@onready var _main_menu_button: Button = $ButtonContainer/MainMenuButton if has_node("ButtonContainer/MainMenuButton") else null
@onready var _tile_grid: GridContainer = $TileGrid if has_node("TileGrid") else null

var _result_data: Dictionary = {}


func _ready() -> void:
	if _play_again_button:
		_play_again_button.pressed.connect(_on_play_again_pressed)
	if _main_menu_button:
		_main_menu_button.pressed.connect(_on_main_menu_pressed)

	SignalBus.run_ended.connect(_on_run_ended)

	# If we already have result data from the run that just ended, use it


func _exit_tree() -> void:
	SignalBus.run_ended.disconnect(_on_run_ended)
	_load_result_from_state()
	_display_results()

	AudioManager.play_music("results")


func _load_result_from_state() -> void:
	# Build result data from GameState's session stats
	var answered: int = GameState.cards_answered_today
	var correct: int = GameState.correct_answers_today
	var accuracy: float = (float(correct) / float(answered) * 100.0) if answered > 0 else 0.0

	_result_data = {
		"run_type": GameState.current_run_type if GameState.current_run_type != "" else "easy",
		"coins": GameState.run_coins_earned,
		"tiles": GameState.run_tiles_earned.duplicate(),
		"best_combo": GameState.best_combo,
		"rounds": GameState.current_round,
		"hearts_remaining": GameState.current_hearts,
		"accuracy": accuracy,
		"total_answered": answered,
		"correct_count": correct,
	}


func _on_run_ended(result: Dictionary) -> void:
	_result_data = result
	_display_results()


func _display_results() -> void:
	if _result_data.is_empty():
		return

	var accuracy: float = _result_data.get("accuracy", 0.0)
	var best_combo: int = _result_data.get("best_combo", 0)
	var coins: int = _result_data.get("coins", 0)
	var tiles: Dictionary = _result_data.get("tiles", {})
	var rounds: int = _result_data.get("rounds", 0)
	var hearts: int = _result_data.get("hearts_remaining", 0)
	var run_type: String = _result_data.get("run_type", "easy")

	if _title_label:
		if hearts <= 0 and run_type == "challenge":
			_title_label.text = "Game Over"
		else:
			_title_label.text = "Run Complete!"

	if _accuracy_label:
		_accuracy_label.text = "Accuracy: %.0f%%" % accuracy

	if _combo_label:
		_combo_label.text = "Best Combo: %d" % best_combo

	if _coins_label:
		_coins_label.text = "Coins Earned: %d" % coins

	var total_tiles: int = 0
	for ch in tiles:
		total_tiles += int(tiles[ch])
	if _tiles_label:
		_tiles_label.text = "Tiles Earned: %d" % total_tiles

	if _rounds_label:
		_rounds_label.text = "Rounds: %d" % rounds

	if _hearts_label:
		_hearts_label.text = "Hearts Left: %d" % hearts

	_display_tile_grid(tiles)

	# Save after each run
	SaveManager.save_game()


func _display_tile_grid(tiles: Dictionary) -> void:
	if _tile_grid == null:
		return
	for child in _tile_grid.get_children():
		child.queue_free()
	for ch in tiles:
		var count: int = tiles[ch]
		var label := Label.new()
		label.text = "%s x%d" % [ch, count]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_tile_grid.add_child(label)


func _on_play_again_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("run_select")


func _on_main_menu_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("main_menu")
