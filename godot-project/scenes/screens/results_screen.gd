## ResultsScreen — Shows run results: accuracy, rounds, and the player's
## carried-forward hand with total power. Pulls data from
## GameState.last_run_summary (set by GameState.end_run before this screen
## comes online, so we read it on _ready rather than via the run_ended
## signal — that signal already fired by the time we're in the tree).
class_name ResultsScreen
extends Control

@onready var _accuracy_label: Label = $StatsContainer/AccuracyLabel if has_node("StatsContainer/AccuracyLabel") else null
@onready var _rounds_label: Label = $StatsContainer/RoundsLabel if has_node("StatsContainer/RoundsLabel") else null
@onready var _power_label: Label = $StatsContainer/PowerLabel if has_node("StatsContainer/PowerLabel") else null
@onready var _hand_cards_label: Label = $StatsContainer/HandCardsLabel if has_node("StatsContainer/HandCardsLabel") else null
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

	_load_result_from_state()
	_display_results()
	AudioManager.play_music("results")


func _exit_tree() -> void:
	SignalBus.run_ended.disconnect(_on_run_ended)


func _load_result_from_state() -> void:
	if GameState.last_run_summary.is_empty():
		return
	_result_data = GameState.last_run_summary.duplicate()


func _on_run_ended(result: Dictionary) -> void:
	_result_data = result
	_display_results()


func _display_results() -> void:
	if _result_data.is_empty():
		return

	if _title_label:
		_title_label.text = "Run Complete!"

	if _accuracy_label:
		# accuracy from RunManager is a 0..1 ratio; render as a percentage.
		var accuracy: float = _result_data.get("accuracy", 0.0)
		_accuracy_label.text = "Accuracy: %.0f%%" % (accuracy * 100.0)

	if _rounds_label:
		var rounds: int = _result_data.get("rounds_completed", 0)
		_rounds_label.text = "Rounds: %d" % rounds

	var hand: Array = _result_data.get("hand_cards", [])
	if _power_label:
		var total_power: int = _result_data.get("total_hand_power", 0)
		_power_label.text = "Hand: %d cards · Total Power: %d" % [hand.size(), total_power]

	if _hand_cards_label:
		_hand_cards_label.text = _format_hand_cards(hand)

	SaveManager.save_game()


## "好  Power 8\n大  Power 4" — one line per HandCard, sorted strongest first
## so the best card stands out. Returns "" for an empty hand.
static func _format_hand_cards(hand_cards: Array) -> String:
	if hand_cards.is_empty():
		return ""
	var sorted := hand_cards.duplicate()
	sorted.sort_custom(func(a: HandCard, b: HandCard) -> bool:
		return a.get_total_power() > b.get_total_power()
	)
	var lines: Array[String] = []
	for hc in sorted:
		lines.append("%s  Power %d" % [hc.card_id, hc.get_total_power()])
	return "\n".join(lines)


func _on_play_again_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("run_select")


func _on_main_menu_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("main_menu")


func _warn_missing_nodes() -> void:
	if _accuracy_label == null:
		push_warning("results_screen.gd: missing node _accuracy_label")
	if _rounds_label == null:
		push_warning("results_screen.gd: missing node _rounds_label")
	if _power_label == null:
		push_warning("results_screen.gd: missing node _power_label")
	if _hand_cards_label == null:
		push_warning("results_screen.gd: missing node _hand_cards_label")
	if _title_label == null:
		push_warning("results_screen.gd: missing node _title_label")
	if _play_again_button == null:
		push_warning("results_screen.gd: missing node _play_again_button")
	if _main_menu_button == null:
		push_warning("results_screen.gd: missing node _main_menu_button")
