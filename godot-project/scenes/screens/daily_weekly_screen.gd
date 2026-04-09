## DailyWeeklyScreen — Shows daily sentence goal and weekly trial progress.
## Displays today's sentence, tiles needed, weekly trial requirements and progress.
class_name DailyWeeklyScreen
extends Control

@onready var _title_label: Label = $TitleLabel if has_node("TitleLabel") else null
@onready var _daily_section: VBoxContainer = $DailySection if has_node("DailySection") else null
@onready var _daily_sentence_label: Label = $DailySection/SentenceLabel if has_node("DailySection/SentenceLabel") else null
@onready var _daily_meaning_label: Label = $DailySection/MeaningLabel if has_node("DailySection/MeaningLabel") else null
@onready var _daily_tiles_label: Label = $DailySection/TilesLabel if has_node("DailySection/TilesLabel") else null
@onready var _daily_status_label: Label = $DailySection/StatusLabel if has_node("DailySection/StatusLabel") else null
@onready var _daily_complete_button: Button = $DailySection/CompleteButton if has_node("DailySection/CompleteButton") else null
@onready var _weekly_section: VBoxContainer = $WeeklySection if has_node("WeeklySection") else null
@onready var _weekly_title_label: Label = $WeeklySection/WeeklyTitle if has_node("WeeklySection/WeeklyTitle") else null
@onready var _weekly_progress_label: Label = $WeeklySection/ProgressLabel if has_node("WeeklySection/ProgressLabel") else null
@onready var _weekly_days_label: Label = $WeeklySection/DaysLabel if has_node("WeeklySection/DaysLabel") else null
@onready var _weekly_reward_label: Label = $WeeklySection/RewardLabel if has_node("WeeklySection/RewardLabel") else null
@onready var _back_button: Button = $BackButton if has_node("BackButton") else null

var _daily_manager: DailyGoalManager
var _weekly_manager: WeeklyTrialManager


func _ready() -> void:
	_warn_missing_nodes()
	_daily_manager = DailyGoalManager.new(GameState.sentence_db)
	_weekly_manager = WeeklyTrialManager.new(GameState.sentence_db)

	if _back_button:
		_back_button.pressed.connect(_on_back_pressed)
	if _daily_complete_button:
		_daily_complete_button.pressed.connect(_on_daily_complete_pressed)

	_load_data()
	_update_daily_display()
	_update_weekly_display()


func _load_data() -> void:
	_daily_manager.load_today(GameState.player_hsk_level)
	_weekly_manager.load_current_trial(GameState.player_hsk_level)


func _update_daily_display() -> void:
	if _title_label:
		_title_label.text = "Daily & Weekly Challenges"

	var sentence: String = _daily_manager.get_sentence_display()
	var meaning: String = _daily_manager.get_sentence_meaning()
	var needed: Array[String] = _daily_manager.get_needed_tiles()
	var can_complete: bool = _daily_manager.check_completion(GameState.tile_inventory)
	var is_done: bool = _daily_manager.is_completed or GameState.daily_sentence_completed_today

	if _daily_sentence_label:
		if sentence.is_empty():
			_daily_sentence_label.text = "No daily sentence available"
		else:
			_daily_sentence_label.text = sentence

	if _daily_meaning_label:
		_daily_meaning_label.text = meaning

	if _daily_tiles_label:
		if needed.is_empty():
			_daily_tiles_label.text = ""
		else:
			# Show which tiles are needed and which the player has
			var parts: Array[String] = []
			for ch in needed:
				var owned: int = GameState.tile_inventory.get(ch, 0)
				parts.append("%s (%d)" % [ch, owned])
			_daily_tiles_label.text = "Tiles needed: %s" % ", ".join(parts)

	if _daily_status_label:
		if is_done:
			_daily_status_label.text = "Completed!"
			_daily_status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		elif can_complete:
			_daily_status_label.text = "Ready to complete!"
			_daily_status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		else:
			_daily_status_label.text = "Collect more tiles from runs"
			_daily_status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	if _daily_complete_button:
		_daily_complete_button.visible = can_complete and not is_done
		_daily_complete_button.disabled = not can_complete or is_done


func _update_weekly_display() -> void:
	var requirements: Dictionary = _weekly_manager.get_trial_requirements()
	var sentences_completed: int = requirements.get("sentences_completed", 0)
	var sentences_required: int = requirements.get("sentences_required", 3)
	var reward_coins: int = requirements.get("reward_coins", 200)
	var days_left: int = _weekly_manager.get_days_remaining()
	var is_complete: bool = _weekly_manager.is_trial_complete()

	if _weekly_title_label:
		_weekly_title_label.text = "Weekly Trial"

	if _weekly_progress_label:
		if is_complete:
			_weekly_progress_label.text = "Trial complete! %d / %d" % [sentences_completed, sentences_required]
			_weekly_progress_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		else:
			_weekly_progress_label.text = "Progress: %d / %d sentences" % [sentences_completed, sentences_required]

	if _weekly_days_label:
		if days_left == 0:
			_weekly_days_label.text = "Last day!"
		else:
			_weekly_days_label.text = "%d days remaining" % days_left

	if _weekly_reward_label:
		if is_complete:
			_weekly_reward_label.text = "Reward claimed: %d coins" % reward_coins
		else:
			_weekly_reward_label.text = "Reward: %d coins" % reward_coins


func _on_daily_complete_pressed() -> void:
	if _daily_manager.is_completed or GameState.daily_sentence_completed_today:
		return

	var can_complete: bool = _daily_manager.check_completion(GameState.tile_inventory)
	if not can_complete:
		return

	# Spend the tiles
	var needed: Array[String] = _daily_manager.get_needed_tiles()
	if not GameState.spend_tiles(needed):
		return

	# Complete and get reward
	var reward: Dictionary = _daily_manager.complete_daily(needed)
	GameState.daily_sentence_completed_today = true

	var reward_coins: int = reward.get("reward_coins", 0)
	if reward_coins > 0:
		GameState.add_coins(reward_coins)

	AudioManager.play_correct()
	_update_daily_display()
	SaveManager.save_game()


func _on_back_pressed() -> void:
	SignalBus.screen_transition_requested.emit("main_menu")


func _warn_missing_nodes() -> void:
	if _title_label == null:
		push_warning("daily_weekly_screen.gd: missing node _title_label")
	if _daily_section == null:
		push_warning("daily_weekly_screen.gd: missing node _daily_section")
	if _daily_sentence_label == null:
		push_warning("daily_weekly_screen.gd: missing node _daily_sentence_label")
	if _daily_meaning_label == null:
		push_warning("daily_weekly_screen.gd: missing node _daily_meaning_label")
	if _daily_tiles_label == null:
		push_warning("daily_weekly_screen.gd: missing node _daily_tiles_label")
	if _daily_status_label == null:
		push_warning("daily_weekly_screen.gd: missing node _daily_status_label")
	if _daily_complete_button == null:
		push_warning("daily_weekly_screen.gd: missing node _daily_complete_button")
	if _weekly_section == null:
		push_warning("daily_weekly_screen.gd: missing node _weekly_section")
	if _weekly_title_label == null:
		push_warning("daily_weekly_screen.gd: missing node _weekly_title_label")
	if _weekly_progress_label == null:
		push_warning("daily_weekly_screen.gd: missing node _weekly_progress_label")
	if _weekly_days_label == null:
		push_warning("daily_weekly_screen.gd: missing node _weekly_days_label")
	if _weekly_reward_label == null:
		push_warning("daily_weekly_screen.gd: missing node _weekly_reward_label")
	if _back_button == null:
		push_warning("daily_weekly_screen.gd: missing node _back_button")
