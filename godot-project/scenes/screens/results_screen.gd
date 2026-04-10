## ResultsScreen — Shows run results including accuracy and coins earned.
## Pulls data from GameState's last run result. Offers Play Again and Main Menu buttons.
class_name ResultsScreen
extends Control

@onready var _accuracy_label: Label = $StatsContainer/AccuracyLabel if has_node("StatsContainer/AccuracyLabel") else null
@onready var _coins_label: Label = $StatsContainer/CoinsLabel if has_node("StatsContainer/CoinsLabel") else null
@onready var _rounds_label: Label = $StatsContainer/RoundsLabel if has_node("StatsContainer/RoundsLabel") else null
@onready var _title_label: Label = $TitleLabel if has_node("TitleLabel") else null
@onready var _play_again_button: Button = $ButtonContainer/PlayAgainButton if has_node("ButtonContainer/PlayAgainButton") else null
@onready var _main_menu_button: Button = $ButtonContainer/MainMenuButton if has_node("ButtonContainer/MainMenuButton") else null

var _result_data: Dictionary = {}


func _ready() -> void:
	_warn_missing_nodes()
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
	# Use the summary stored by GameState.end_run()
	if not GameState.last_run_summary.is_empty():
		_result_data = GameState.last_run_summary.duplicate()
		# Ensure accuracy is present
		if not _result_data.has("accuracy"):
			var total: int = _result_data.get("total_cards", 0)
			var correct: int = _result_data.get("correct_count", 0)
			_result_data["accuracy"] = (float(correct) / float(total) * 100.0) if total > 0 else 0.0


func _on_run_ended(result: Dictionary) -> void:
	_result_data = result
	_display_results()


func _display_results() -> void:
	if _result_data.is_empty():
		return

	var accuracy: float = _result_data.get("accuracy", 0.0)
	var coins: int = _result_data.get("coins", 0)
	var rounds: int = _result_data.get("rounds", 0)
	if _title_label:
		_title_label.text = "Run Complete!"

	if _accuracy_label:
		_accuracy_label.text = "Accuracy: %.0f%%" % accuracy

	if _coins_label:
		_coins_label.text = "Coins Earned: %d" % coins

	if _rounds_label:
		_rounds_label.text = "Rounds: %d" % rounds

	# Save after each run
	SaveManager.save_game()


func _on_play_again_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("run_select")


func _on_main_menu_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("main_menu")


func _warn_missing_nodes() -> void:
	if _accuracy_label == null:
		push_warning("results_screen.gd: missing node _accuracy_label")
	if _coins_label == null:
		push_warning("results_screen.gd: missing node _coins_label")
	if _rounds_label == null:
		push_warning("results_screen.gd: missing node _rounds_label")
	if _title_label == null:
		push_warning("results_screen.gd: missing node _title_label")
	if _play_again_button == null:
		push_warning("results_screen.gd: missing node _play_again_button")
	if _main_menu_button == null:
		push_warning("results_screen.gd: missing node _main_menu_button")
