## MainMenu — Main menu screen with navigation to all game modes and screens.
## Provides buttons for Play (run select), Collection, Shop, Profile, and Settings.
class_name MainMenu
extends Control

@onready var _play_button: Button = $VBoxContainer/PlayButton if has_node("VBoxContainer/PlayButton") else null
@onready var _collection_button: Button = $VBoxContainer/CollectionButton if has_node("VBoxContainer/CollectionButton") else null
@onready var _shop_button: Button = $VBoxContainer/ShopButton if has_node("VBoxContainer/ShopButton") else null
@onready var _profile_button: Button = $VBoxContainer/ProfileButton if has_node("VBoxContainer/ProfileButton") else null
@onready var _settings_button: Button = $VBoxContainer/SettingsButton if has_node("VBoxContainer/SettingsButton") else null
@onready var _daily_button: Button = $VBoxContainer/DailyButton if has_node("VBoxContainer/DailyButton") else null
@onready var _title_label: Label = $TitleLabel if has_node("TitleLabel") else null
@onready var _coin_display: Control = $CoinCounter if has_node("CoinCounter") else null
@onready var _streak_display: Control = $StreakDisplay if has_node("StreakDisplay") else null


func _ready() -> void:
	_connect_buttons()
	_update_displays()
	GameState.check_daily_reset()
	AudioManager.play_music("main_menu")

	SignalBus.coins_changed.connect(_on_coins_changed)
	SignalBus.streak_updated.connect(_on_streak_updated)


func _connect_buttons() -> void:
	if _play_button:
		_play_button.pressed.connect(_on_play_pressed)
	if _collection_button:
		_collection_button.pressed.connect(_on_collection_pressed)
	if _shop_button:
		_shop_button.pressed.connect(_on_shop_pressed)
	if _profile_button:
		_profile_button.pressed.connect(_on_profile_pressed)
	if _settings_button:
		_settings_button.pressed.connect(_on_settings_pressed)
	if _daily_button:
		_daily_button.pressed.connect(_on_daily_pressed)


func _update_displays() -> void:
	if _title_label:
		_title_label.text = "Nice"
	if _coin_display and _coin_display.has_method("set_count"):
		_coin_display.set_count(GameState.total_coins)
	if _streak_display and _streak_display.has_method("set_streak"):
		_streak_display.set_streak(GameState.daily_streak)


func _on_play_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("run_select")


func _on_collection_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("collection")


func _on_shop_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("shop")


func _on_profile_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("profile")


func _on_settings_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("settings")


func _on_daily_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("daily_weekly")


func _on_coins_changed(_amount: int, total: int) -> void:
	if _coin_display and _coin_display.has_method("set_count"):
		_coin_display.set_count(total)


func _on_streak_updated(days: int) -> void:
	if _streak_display and _streak_display.has_method("set_streak"):
		_streak_display.set_streak(days)
